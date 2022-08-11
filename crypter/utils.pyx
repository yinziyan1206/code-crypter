__author__ = 'ziyan.yin'
__describe__ = ''

import builtins

cdef str _translate(str ctx):
    cdef int i2
    cdef list c_arr = ['' for _ in range(100)]
    cdef int n = len(ctx)
    n -= 1
    cdef int i = n

    while i >= 0:
        i2 = i - 1
        c_arr[i] = chr(ord(ctx[i]) ^ 49)
        if i2 < 0:
            break
        n = i2 - 1
        c_arr[i2] = chr(ord(ctx[i2]) ^ 122)
        i = n
    return ''.join(c_arr)


def translate(ctx: str) -> str:
    return _translate(ctx)


def apply(ctx: str, obj: object = builtins) -> callable:
    if obj is None:
        raise ValueError('obj is None')
    return getattr(obj, translate(ctx))
