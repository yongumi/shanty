__author__ = 'schwa'

import re
import click

class RegexParamType(click.ParamType):
    name = 'string'

    def __init__(self, pattern):
        self.pattern = pattern

    def convert(self, value, param, ctx):
        if not re.match(self.pattern, value):
            self.fail('Value \'%s\' does not match pattern r\'%s\'' % (value, self.pattern))
        else:
            return value

REGEX = RegexParamType
