
from dataclasses import dataclass
from typing import Tuple

class Args:
    def __repr__(self) -> str:
        n_args = len(self.__dataclass_fields__)
        info = f'--{self.__class__.__name__} ({n_args})\n'
        for i, arg in enumerate(self.__dataclass_fields__):
            prefix = '--' if i == n_args-1 else '|-'
            suffix = '' if i == n_args-1 else '\n'
            info += f'\t{prefix} {arg:20s}: {getattr(self, arg)}{suffix}'
        return info
    
@dataclass(repr=False)    
class ModelArgs(Args):
    # basic informations
    name:str = 'Mymodel'
    version:str = 'base_model'
    # model params
    input_shape:Tuple = (1, 2048)
    num_classes:int = 4
    batchnorm:bool = True
    ...

@dataclass(repr=False)
class DatasetArgs(Args):
    # basic informations
    dataset_name:str
    # preprocessing
    normalize:bool = False
    slice_length:int = 2048
    num_each_group:int = 1000
    downsample:bool = True
    train_val_test:Tuple = (0.5, 0.5, 0)
    ...
    
@dataclass(repr=False)
class TrainArgs(Args):
    # device
    device:str = None
    num_worker:int = 1
    # model training
    max_epochs:int = 50
    train_batch:int = 128
    test_batch:int = 256
    lr:float = 0.001
    warm_up_steps:int = 4000
    # optimization
    optimizer_name:str = 'SGD'
    loss_fun:str = 'cross_entropy'
    momentum:float = 0.8
    # save, load and display information
    save_best:bool = True
    checkpoint_dir:str = './logs/'
    print_step:int = 10
    # others
    random_seed:int = 1
    ...
