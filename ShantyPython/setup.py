#!/usr/bin/env python

#from distutils.core import setup
from setuptools import setup

setup(name='shanty',
    version='0.1b1',
    description='shanty',
    author='Jonathan Wight',
    author_email='jwight@mac.com',
    url='http://schwa.io/',
    packages=['shanty'],
#    py_modules = ['shanty'],
    scripts=['scripts/shanty'],
    install_requires=['twisted > 12.0', 'docopt >= 0.6', 'pybonjour >= 1.1', 'six'],
    )
