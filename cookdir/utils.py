import os

def get_path(recipe, base_dir):
    if os.path.isfile(recipe):
        recipe_file = recipe
    elif os.path.isfile(f"{base_dir}/recipe/{recipe}.yml"):
        recipe_file = f"{base_dir}/recipe/{recipe}.yml"
    else:
        print("Input recipe is not a valid template name or filepath, please check it!")
        return None
    return recipe_file
