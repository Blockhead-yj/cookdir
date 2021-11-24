import yaml
import os
import argparse
from functools import singledispatch

# parse the arguments from command line 
parser = argparse.ArgumentParser()

parser.add_argument("-r", "--recipe", type=str, help="Select the recipe(template) of directories")
parser.add_argument("-n", "--name", type=str, default="default", help="The name of your project")
parser.add_argument("-d", "--destination", type=str, default="./", help="The root directory where your directories will be made")

# set the base directory, to get access to recipes without path error
base_dir = __file__[:__file__.rfind(os.path.sep)]

# make directories according recipe
@singledispatch
def cookdirs(recipe, root="."):
    ValueError("Your recipe is poisonous, please check it!")

@cookdirs.register(list)
def _cooklist(recipe, root="."):
    for d in recipe:
        cookdirs(d, root)

@cookdirs.register(dict)
def _cookdict(recipe, root="."):
    for k in recipe:
        root_dir = cookdirs(k, root)
        cookdirs(recipe[k], root_dir)

@cookdirs.register(str)
def _cookstr(recipe, root="."):
    path = os.path.join(root, recipe)
    if recipe.find(".") >= 0:
        if not os.path.isfile(path):
            print(f"Creating file {path}...")
            open(path, "w").close()
    else:
        if not os.path.isdir(path):
            print(f"Creating directory {path}...")
            os.mkdir(path)
    return path

@cookdirs.register(int)
def _cooknum(recipe, root="."):
    return cookdirs(str(recipe), root)


# def show(recipe):
#     with open(f"./recipe/{recipe}", "r") as f:
#         for line in f:
#             print(line, end="")

if __name__=="__main__":
    args = parser.parse_args()

    # replace the "project_name" in template with true project name and parse it
    with open(f"{base_dir}/recipe/{args.recipe}.yml", "r") as f:
        recipe = f.read()
        try:
            recipe = yaml.load(recipe.replace("project_name", args.name), Loader=yaml.FullLoader)
        except yaml.parser.ParserError:
                print("Your recipe is poisonous, please check it!")

    cookdirs(recipe, root=args.destination)
    print("Cooking is complete, please enjoy!")
