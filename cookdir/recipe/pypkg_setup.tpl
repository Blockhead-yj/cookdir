import setuptools

with open("README.md", "r") as f:
    long_description = f.read()

setuptools.setup(
    name="pkg_name",
    version="0.0.0",
    author="author",
    author_email="youmail@mail.com",
    description="what your package do",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="url to your homepage",
    packages=setuptools.find_packages(),
    classifiers=[],
    python_requires='>=required_python_version',
)
