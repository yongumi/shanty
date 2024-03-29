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
#    scripts=['scripts/shanty'],
    install_requires=['pybonjour >= 1.1', 'six', 'click', 'trollius'],
    entry_points='''
        [console_scripts]
        shanty=shanty.tool:main
        ''',
    )
