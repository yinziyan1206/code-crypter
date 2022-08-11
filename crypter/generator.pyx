__author__ = 'ziyan.yin'
__describe__ = ''

import os
from typing import Generator
import re

from crypter.utils import translate

func_regex = re.compile('([^\'"]*?)(?P<object_name>[a-zA-Z0-9._]+)\.(?P<function_name>[^.() ]+)\((?P<params>[^)]*?)\)')
str_regex = re.compile("([^'\"]*?)(?P<prefix>[a-z]?)'(?P<strings>[a-zA-Z0-9._\-%@]+)'")

builtins_regex = {
    'print': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)print\((?P<params>[^)]*?)\)'),
    'str': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)str\((?P<params>[^)]*?)\)'),
    'int': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)int\((?P<params>[^)]*?)\)'),
    'float': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)float\((?P<params>[^)]*?)\)'),
    'list': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)list\((?P<params>[^)]*?)\)'),
    'set': re.compile('(.*?)(?P<prefix>[a-zA-Z0-9._]?)set\((?P<params>[^)]*?)\)'),
}

cdef dict func_matches(str ctx):
    data = func_regex.match(ctx)
    if data:
        return data.groupdict()
    else:
        return {}


cdef dict str_matches(str ctx):
    data = str_regex.match(ctx)
    if data:
        return data.groupdict()
    else:
        return {}


cdef dict builtins_matches(str ctx):
    for name, regex in builtins_regex.items():
        data = regex.match(ctx)
        if data and not data['prefix']:
            return data.groupdict() | {'function_name': name}
    return {}


def load(file_name: str) -> Generator[str, None, None]:
    with open(file_name, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for line in lines:
            yield line.strip('\n')


def str_format(ctx: str):
    return str(ctx.encode()).removeprefix('b')


def collect(file_name: str):
    for code in load(file_name):
        f = func_matches(code)
        s = str_matches(code)
        b = builtins_matches(code)
        if b:
            oc = f"{b['prefix']}{b['function_name']}({b['params']})"
            key = str_format(translate(b['function_name']))
            rc = f"{b['prefix']}utils.apply({key})({b['params']})"
            code = code.replace(oc, rc)
        if f:
            oc = f"{f['object_name']}.{f['function_name']}({f['params']})"
            key = str_format(translate(f['function_name']))
            rc = f"utils.apply({key}, obj={f['object_name']})({f['params']})"
            code = code.replace(oc, rc)
        if s:
            oc = f"'{s['strings']}'"
            key = str_format(translate(s['strings']))
            rc = f"utils.translate({key})"
            prefix: str = s['prefix']
            if prefix == 'b':
                oc = 'b' + oc
                rc = rc + '.encode()'
            elif prefix == 'u':
                oc = 'u' + oc
            elif prefix == 'r':
                oc = 'r' + oc
            code = code.replace(oc, rc)
        yield code


def transform(file_name: str, output: str):
    with open(output, 'w', encoding='utf-8') as f:
        f.write('from crypter import utils\n')
        for code in collect(file_name):
            f.write(code + '\n')


def transform_all(input_dir: str):
    output_dir = input_dir + '_transformed'
    os.mkdir(output_dir)
    for file_name in os.listdir(input_dir):
        if file_name.endswith('.py'):
            transform(os.path.join(input_dir, file_name), os.path.join(output_dir, file_name))
