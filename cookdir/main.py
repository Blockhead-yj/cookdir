import enum
import os
import re
from functools import singledispatch

import glob
import fire
import yaml

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
            print(f"File {path} exists, skip it!")
    else:
        if not os.path.isdir(path):
            print(f"Creating directory {path}...")
            os.mkdir(path)
        else:
            print(f"Directory {path} exists, skip it!")
    return path

@cookdirs.register(int)
def _cooknum(recipe, root="."):
    return cookdirs(str(recipe), root)


def show(recipe=None):
    """
    list all accessible recipe or show the content of a particular recipe

    Parameters
    ----------
    recipe: str
        The template name or a template file, if not defined, it will show all accessible template names.
    Returns
    -------

    """
    if recipe is None:
        print("recipes: ")
        for i, f in enumerate(list_recipes()):
            recipe_name = re.search("(.*).yml", f)[1]
            print(f'{i}. {recipe_name}')
    else:
        with open(f"{base_dir}/recipe/{recipe}.yml", "r") as f:
            for line in f:
                print(line, end="")

def list_recipes():
    recipes = glob.glob(os.path.join(base_dir,"recipe","*.yml"))
    return recipes

# cooking
def cook(recipe, name="DEFAULT", destination="."):
    """
    make directories and initialize files according recipe(template)

    Parameters
    ----------
    recipe: str
        The template name or a template file
    name: str
        The name of your project
    destination: str
        The root directory where your directories will be made

    Returns
    -------

    """
    if os.path.isfile(recipe):
        recipe_file = recipe
    elif isinstance(recipe, int) & recipe in range(1, len(list_recipes())):
        recipe_file = f"{list_recipes()[recipe]}"
    elif os.path.isfile(f"{base_dir}/recipe/{recipe}.yml"):
        recipe_file = f"{base_dir}/recipe/{recipe}.yml"
    else:
        print("Input recipe is not a valid template name or filename, please check it!")
        return None
    # replace all "DEFAULT" in template with true project name and parse it
    with open(recipe_file, "r") as f:
        recipe = f.read()
        try:
            recipe = yaml.load(recipe.replace("DEFAULT", name), Loader=yaml.FullLoader)
        except yaml.parser.ParserError:
                print("Your recipe is poisonous, please check it!")

    cookdirs(recipe, root=destination)
    print("Cooking is complete, please enjoy!")

def cli():
    fire.Fire(
        {
            "cook": cook,
            "list": show
        }
    )

if __name__=='__main__':
    cli()
