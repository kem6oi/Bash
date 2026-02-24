from setuptools import setup, find_packages

setup(
    name="bash_toolkit",
    version="0.1.0",
    description="Python SDK for Bash Security & IoT Toolkit",
    author="Jules",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
)
