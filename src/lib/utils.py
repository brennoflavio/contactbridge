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
import secrets
import string
from dataclasses import asdict, is_dataclass
from typing import Any, Callable


def short_string():
    return "".join(secrets.choice(string.ascii_letters) for _ in range(8))


def dataclass_to_dict(func: Callable) -> Callable:
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        response = func(*args, **kwargs)
        if is_dataclass(response):
            return asdict(response)  # type: ignore
        else:
            return response

    return wrapper
