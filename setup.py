import setuptools

with open("README.md", "r") as f:
    long_description = f.read()

print(setuptools.find_packages())

setuptools.setup(
    name="cookdir",
    version="0.1.3",
    author="yjdai",
    author_email="136271877@qq.com",
    description="create directories by template",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Blockhead-yj/cookdir",
    include_package_data=True,
    package_data={
        'cookdir':['recipe/*.yml']
    },
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU General Public License (GPL)",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6', # actually i don't know it, but i write this in 3.6
    install_requires=["fire==0.4.0", "PyYAML==6.0"],
    entry_points={
        'console_scripts':['cookdir=cookdir.main:cli']
    }
)
