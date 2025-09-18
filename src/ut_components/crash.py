"""
Copyright (C) 2025  Brenno Flávio de Almeida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3.

ut-components is distributed in the hope that it will be useful,
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
    """
    Enable or disable automatic crash reporting for the application.

    This function persists the crash reporting preference in the application's
    key-value store. When enabled, decorated functions will automatically send
    crash reports to the configured URL when exceptions occur.

    Args:
        enabled (bool): True to enable crash reporting, False to disable it.
            This preference is stored persistently and will be remembered
            across application restarts.

    Example:
        >>> from src.ut_components import setup
        >>> from src.ut_components.crash import set_crash_report
        >>>
        >>> # Initialize the library with crash URL
        >>> setup(app_name="MyApp", crash_report_url="https://api.myapp.com/crashes")
        >>>
        >>> # Enable crash reporting
        >>> set_crash_report(True)
        >>>
        >>> # Later, disable it if user opts out
        >>> set_crash_report(False)
    """
    with KV() as kv:
        kv.put("crash.enabled", enabled)


def get_crash_report() -> bool:
    """
    Check if crash reporting is currently enabled for the application.

    Retrieves the crash reporting preference from the persistent key-value store.
    This function is used internally by the crash_reporter decorator to determine
    whether to send crash reports when exceptions occur.

    Returns:
        bool: True if crash reporting is enabled, False otherwise.
            Returns False by default if no preference has been set.

    Example:
        >>> from src.ut_components.crash import get_crash_report, set_crash_report
        >>>
        >>> # Check initial state (defaults to False)
        >>> is_enabled = get_crash_report()
        >>> print(f"Crash reporting: {is_enabled}")  # Output: Crash reporting: False
        >>>
        >>> # Enable crash reporting
        >>> set_crash_report(True)
        >>> is_enabled = get_crash_report()
        >>> print(f"Crash reporting: {is_enabled}")  # Output: Crash reporting: True
    """
    with KV() as kv:
        return kv.get("crash.enabled", False, True) or False


def crash_reporter(func: Callable) -> Callable:
    """
    Decorator that automatically reports unhandled exceptions to a crash reporting service.

    This decorator wraps functions to catch any unhandled exceptions and automatically
    send crash reports to the configured URL endpoint if crash reporting is enabled.
    The original exception is always re-raised to maintain normal error flow, ensuring
    that the application's error handling logic is not disrupted.

    The decorator checks if crash reporting is enabled before sending any data, respecting
    user privacy preferences. It requires the library to be initialized with a valid
    crash report URL using the setup() function.

    Args:
        func (Callable): The function to be decorated with crash reporting capability.

    Returns:
        Callable: The wrapped function that includes crash reporting functionality.

    Raises:
        AssertionError: If crash reporting is enabled but CRASH_REPORT_URL_ is not configured.
        Any exception raised by the decorated function is re-raised after reporting.

    Example:
        >>> from src.ut_components import setup
        >>> from src.ut_components.crash import crash_reporter, set_crash_report
        >>>
        >>> # Initialize the library with crash reporting URL
        >>> setup(app_name="MyApp", crash_report_url="https://api.myapp.com/crashes")
        >>> set_crash_report(True)
        >>>
        >>> # Decorate a function that might crash
        >>> @crash_reporter
        ... def risky_operation(data):
        ...     # This could raise an exception
        ...     result = process_data(data)
        ...     return result
        >>>
        >>> # When the function raises an exception, it will be reported
        >>> try:
        ...     risky_operation(invalid_data)
        ... except Exception as e:
        ...     # Exception is still raised after being reported
        ...     print(f"Operation failed: {e}")
        >>>
        >>> # Can also be used with class methods
        >>> class DataProcessor:
        ...     @crash_reporter
        ...     def process(self, data):
        ...         return data.transform()
    """

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
