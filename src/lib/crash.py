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
import traceback
from typing import Any, Callable

from . import CRASH_REPORT_URL_, http
from .kv import KV


def set_crash_report(enabled: bool):
    with KV() as kv:
        kv.put("crash.enabled", enabled)


def get_crash_report() -> bool:
    with KV() as kv:
        return kv.get("crash.enabled", False, True) or False


def crash_reporter(func: Callable) -> Callable:
    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        try:
            return func(*args, **kwargs)
        except Exception:
            if get_crash_report():
                assert CRASH_REPORT_URL_
                traceback_str = traceback.format_exc()
                http.post(url=CRASH_REPORT_URL_, json={"report": traceback_str})
            raise

    return wrapper
