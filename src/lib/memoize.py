"""
Copyright (C) 2025  Brenno Flávio de Almeida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3.

ut-python-utils is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import functools
import hashlib
import json
from typing import Any, Callable

from .kv import KV


def hash_function_name(func: Callable) -> str:
    function_name = f"{func.__module__}.{func.__name__}"
    return hashlib.sha1(f"{function_name}".encode()).hexdigest()


def hash_function_args(args, kwargs) -> str:
    encoded_args = f"{json.dumps(args, sort_keys=True)}-{json.dumps(kwargs, sort_keys=True)}"
    return hashlib.sha1(f"{encoded_args}".encode()).hexdigest()


def memoize(ttl_seconds: int):
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            hashed_function_name = hash_function_name(func)
            hashed_encoded_args = hash_function_args(args, kwargs)
            with KV() as kv:
                response = kv.get(f"memoize.{hashed_function_name}.{hashed_encoded_args}")
                if response is not None:
                    return response
                result = func(*args, **kwargs)
                kv.put(
                    f"memoize.{hashed_function_name}.{hashed_encoded_args}",
                    result,
                    ttl_seconds=ttl_seconds,
                )
                return result

        return wrapper

    return decorator


def delete_memoized(function: Callable):
    hashed_function_name = hash_function_name(function)
    with KV() as kv:
        kv.delete_partial(f"memoize.{hashed_function_name}")
