# cookdir
## Initializing directories and files by recipe(template)

## Installation

`pip install cookdir`

## Functions:

- [x] create directories and files by a template name or a self-defined template yaml file.
   - Usage:
      - `cookdir cook pypkg pkgname --destination=your_path`
      - `cookdir cook template_file_path name`
- [x] list all existing template, or show the content of a particular template
   - Usage:
      - `cookdir list`
      - `cookdir list pypkg`
- [x] template shortcut
- [x] support file content template so files will be initilized with some content rather than empty

## Template:
A template file looks like:
```
# this template is used for python package

DEFAULT:
  - DEFAULT:
    - __init__.py
  - tests
  - setup.py: pypkg_setup.tpl

```
A string followed by a colon means it is parent directory of the directories/files.
Strings following "-" means these directories are in the same level.
A filename followed by a colon and another template file means that the file will be initiated with the content in the template.

You can easily defined your own recipe(template) according the rules.

## Wanting:
Anyone who has some useful recipe(template) can commit PR, and anyone has some function suggestion can commit PR or issues.

I appreciate all of you.
