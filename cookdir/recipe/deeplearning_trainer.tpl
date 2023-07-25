import datetime
from pathlib import Path
import random

import numpy as np
import torch
from torchmetrics import Accuracy
from torch.utils.tensorboard import SummaryWriter
from torch.optim import SGD, Adam
from torch.optim.lr_scheduler import LambdaLR
import torch.nn.functional as F

import data
import models
from config import ModelArgs, DatasetArgs, TrainArgs
from utils.from_lambda import to_str, parse_lambda

class Trainer:
    def __init__(self, model_args:ModelArgs, data_args:DatasetArgs, training_args:TrainArgs):
        self.model_args = model_args
        self.data_args = data_args
        self.train_args = training_args
        
        if self.train_args.device is None:
            self.train_args.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        
        # logging the params 
        time = datetime.datetime.strftime(datetime.datetime.now(), '%m%d%H%M')
        log_path = Path(self.train_args.checkpoint_dir) / self.model_args.name / f'{self.model_args.version}_{time}'
        self.logger = SummaryWriter(log_path)
        self.logger.add_text('model_args', str(self.model_args))
        self.logger.add_text('data_args', str(self.data_args))
        self.logger.add_text('train_args', str(self.train_args))
        
    def _init_model(self):
        # To be implemented
        # initiate your model here
        model = ...
        return model
    
    def _get_data(self):
        # To be implemented
        # load your data here
        train, val, test = ..., ..., ...
        return train, val, test
    
    def _get_optimizer(self, params):
        if self.train_args.optimizer_name == 'SGD':
            optimizer = SGD(params, self.train_args.lr, self.train_args.momentum)
        elif self.train_args.optimizer_name == 'Adam':
            optimizer = Adam(params, self.train_args.lr)
        # optional
        warmup = self.train_args.warm_up_steps
        total_step = self.data_args.num_each_group * self.model_args.num_classes / self.train_args.train_batch * self.train_args.max_epochs
        self.lr_scheduler = LambdaLR(optimizer, lambda step: step/warmup if step<warmup else 1/(1 + 10*(step-warmup)/total_step)**0.75 )
        return optimizer
    
    def train(self):
        #! set the random seed first!
        Trainer.seed_everything(self.train_args.random_seed)
        # initiate the model and prepare data
        model = self._init_model()
        train, val, test = self._get_data()
        optimizer = self._get_optimizer(model.parameters())
        
        self.epoch = 0
        self.steps = 0
        self.best_metric = -float('inf')
        
        loss_fn = F.cross_entropy
        acc_evaluator = Accuracy('multiclass', num_classes=self.model_args.num_classes)
        acc_evaluator.to(self.train_args.device)
        
        self.logger.add_text('model_structure', str(model).replace('\n', '  \n'))
        self.logger.add_text('lr_schedual', to_str(parse_lambda(self.lr_scheduler.lr_lambdas[0])))
        
        model.to(self.train_args.device)
        for i_epoch in range(self.train_args.max_epochs):
            self.epoch = i_epoch
            print(f'Epoch {i_epoch}:')
            self.train_step(model, train, loss_fn, optimizer, acc_evaluator)
            self.val_step(model, val, loss_fn, acc_evaluator)
            self.test_step(model, test, loss_fn, acc_evaluator)
            
            
    def train_step(self, model, data, loss_fn, optimizer, evaluator):
        # train your model
        #1 普通训练模式, 单一数据源
        model.train()
        if not (isinstance(data, tuple) and len(data)==2):
            for X, y in data:
                X = X.to(self.train_args.device)
                y = y.to(self.train_args.device)
                # predict and calculate the loss
                logits = model(X)
                loss = loss_fn(logits, y)
                # backpropagation
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
                # update lr
                self.lr_scheduler.step()
                # recording training process and display
                self.steps += 1
                if self.steps % self.train_args.print_step == 0:
                    print(f'loss: {loss.item():>8f}')
            # evaluating at the end of epoch
            indictator = evaluator(logits, torch.argmax(y,dim=1)).item()
            evaluator.reset()
        #2 对抗训练模式, 分为source和target两个数据源
        else:
            source, target = data
            for X_source, y_source in source:
                X_target, y_target = next(target)
                source_size = y_source.size(0)
                target_size = y_target.size(0)
                # move the data to gpu
                X_source = X_source.to(self.train_args.device)
                y_source = y_source.to(self.train_args.device)
                X_target = X_target.to(self.train_args.device)
                y_target = y_target.to(self.train_args.device)
                # merge source input and target input
                X = torch.concat([X_source, X_target], dim=0)
                
                # predict and calculate the loss
                features, logits, domain = model(X)
                classification_loss = loss_fn(logits.narrow(0, 0, source_size), y_source)
                domain_label = torch.concat([torch.zeros(source_size), torch.ones(target_size)], dim=0)
                domain_label = domain_label.to(self.train_args.device)
                domain_loss = F.binary_cross_entropy(domain, domain_label.reshape(-1, 1))
                loss = classification_loss + domain_loss
                # backpropagation
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()     
                # update lr
                self.lr_scheduler.step()
                # recording training process and display
                self.step += 1
                if self.step % self.train_args.print_step == 0:
                    print(f'loss: {loss.item():>8f}')
            # evaluating at the end of epoch
            indictator = evaluator(logits.narrow(0, source_size, target_size), torch.argmax(y_target, dim=1)).item()
            evaluator.reset()
            # extra evaluating at the source domain
            indictator_source = evaluator(logits.narrow(0, 0, source_size), torch.argmax(y_source, dim=1)).item()
            evaluator.reset()
            self.logger.add_scalar(f'Train/{evaluator.__class__.__name__}_source', indictator_source, self.step)            
        self.logger.add_scalar(f'Train/{evaluator.__class__.__name__}', indictator, self.step)
        self.logger.add_scalar(f'Train/loss', loss, self.step)
        print(f'Training Evaluation: {evaluator.__class__.__name__} = {indictator:>.4f}')
        
    @torch.no_grad
    def test_step(self, model, data, loss_fn, evaluator, name='test'):
        # test your model
        model.eval()
        
        test_loss = 0
        for X, y in data:
            X = X.to(self.train_args.device)
            y = y.to(self.train_args.device)
            
            # predict and calculate the loss
            logits = model(X)
            test_loss += loss_fn(logits, y)            
            
            evaluator.update(logits, torch.argma(y, dim=1))
            
        test_loss /= len(data)
        indictator = evaluator.compute().item()
        evaluator.reset()
        print(f'{name.capitalize()}: {evaluator.__class__.__name__} = {indictator:>.4f}, mean loss: {test_loss:>.4f}')
        
        if self.train_args.save_best and indictator > self.best_metric:
            self.best_metric = indictator
            torch.save(model.state_dict(), Path(self.train_args.checkpoint_dir)/f'{self.model_args.name}_{self.model_args.versoin}.pth')
    
    def val_step(self, model, data, loss_fn, evaluator, name='validation'):
        self.test_step(model, data, loss_fn, evaluator, name)
    
    @staticmethod        
    def seed_everything(seed):
        torch.manual_seed(seed)       # Current CPU
        torch.cuda.manual_seed(seed)  # Current GPU
        np.random.seed(seed)          # Numpy module
        random.seed(seed)             # Python random module
        torch.backends.cudnn.benchmark = False    # Close optimization
        torch.backends.cudnn.deterministic = True # Close optimization
        torch.cuda.manual_seed_all(seed) # All GPU (Optional)