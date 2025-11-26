import setuptools

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="DEFAULT",
    version="0.0.1",
    author="your_name",
    author_email="your.email@example.com",
    description="A src layout Python package",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/your_username/DEFAULT",
    package_dir={"": "src"},
    packages=setuptools.find_packages(where="src", include=["DEFAULT", "DEFAULT.*"]),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    install_requires=[
        # Add your package dependencies here
        # "requests>=2.25.0",
        # "numpy>=1.19.0",
    ],
)