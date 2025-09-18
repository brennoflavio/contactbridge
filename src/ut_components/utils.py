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
import secrets
import string
from dataclasses import asdict, is_dataclass
from enum import Enum
from typing import Any, Callable


def short_string():
    """
    Generate a cryptographically secure random string identifier.

    This function creates a short, random string that can be used for various
    purposes such as temporary identifiers, session tokens, or unique keys
    in Ubuntu Touch applications. Uses the secrets module to ensure the
    generated string is suitable for security-sensitive contexts.

    Returns:
        str: An 8-character string composed of random ASCII letters (a-z, A-Z).

    Example:
        >>> from src.ut_components.utils import short_string
        >>>
        >>> # Generate a random identifier
        >>> random_id = short_string()
        >>> print(random_id)  # Output: "KjHgFdSa"
        >>>
        >>> # Use for creating unique temporary keys
        >>> temp_key = f"temp_{short_string()}"
        >>> print(temp_key)  # Output: "temp_XyZaBcDe"
    """
    return "".join(secrets.choice(string.ascii_letters) for _ in range(8))


def enum_to_str(obj):
    """
    Convert Enum values to their string representations recursively.

    This utility function traverses through data structures (dicts, lists) and
    converts any Enum instances to their string values. This is particularly
    useful when preparing data for JSON serialization or QML consumption in
    Ubuntu Touch applications, as Enums are not directly serializable.

    Args:
        obj (Any): The object to process. Can be an Enum, dict, list, or any
            other type. Nested structures are handled recursively.

    Returns:
        Any: The same structure with all Enum values replaced by their string
            representations. Non-Enum values are returned unchanged.

    Example:
        >>> from enum import Enum
        >>> from src.ut_components.utils import enum_to_str
        >>>
        >>> class Status(Enum):
        ...     ACTIVE = "active"
        ...     INACTIVE = "inactive"
        ...     PENDING = "pending"
        >>>
        >>> # Convert single Enum
        >>> result = enum_to_str(Status.ACTIVE)
        >>> print(result)  # Output: "active"
        >>>
        >>> # Convert nested structure
        >>> data = {
        ...     "status": Status.PENDING,
        ...     "items": [Status.ACTIVE, Status.INACTIVE],
        ...     "config": {"default": Status.ACTIVE}
        ... }
        >>> result = enum_to_str(data)
        >>> print(result)
        >>> # Output: {"status": "pending", "items": ["active", "inactive"],
        >>> #          "config": {"default": "active"}}
    """
    if isinstance(obj, Enum):
        return obj.value
    elif isinstance(obj, dict):
        return {k: enum_to_str(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [enum_to_str(item) for item in obj]
    return obj


def dataclass_to_dict(func: Callable) -> Callable:
    """
    Decorator to automatically convert dataclass return values to dictionaries.

    This decorator simplifies the process of exposing dataclass-based APIs to
    QML or JSON consumers in Ubuntu Touch applications. It automatically converts
    dataclass instances to dictionaries and handles any Enum values within them,
    making the data readily consumable by QML components without manual conversion.

    The decorator checks if the function's return value is a dataclass instance.
    If it is, it converts it to a dictionary and processes any Enum values to
    their string representations. Non-dataclass return values pass through unchanged.

    Args:
        func (Callable): The function to be decorated. Should return either a
            dataclass instance or any other value.

    Returns:
        Callable: A wrapped function that automatically converts dataclass
            return values to dictionaries with Enum values as strings.

    Example:
        >>> from dataclasses import dataclass
        >>> from enum import Enum
        >>> from src.ut_components.utils import dataclass_to_dict
        >>>
        >>> class Priority(Enum):
        ...     LOW = "low"
        ...     MEDIUM = "medium"
        ...     HIGH = "high"
        >>>
        >>> @dataclass
        ... class Task:
        ...     id: int
        ...     title: str
        ...     priority: Priority
        ...     completed: bool
        >>>
        >>> @dataclass_to_dict
        ... def get_task(task_id: int) -> Task:
        ...     return Task(
        ...         id=task_id,
        ...         title="Implement feature",
        ...         priority=Priority.HIGH,
        ...         completed=False
        ...     )
        >>>
        >>> # The decorator automatically converts the dataclass
        >>> result = get_task(1)
        >>> print(result)
        >>> # Output: {"id": 1, "title": "Implement feature",
        >>> #          "priority": "high", "completed": False}
        >>>
        >>> # Can be used with PyOtherSide for QML integration
        >>> @dataclass_to_dict
        ... def get_user_data():
        ...     @dataclass
        ...     class UserData:
        ...         username: str
        ...         status: Status
        ...     return UserData("john_doe", Status.ACTIVE)
    """

    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        response = func(*args, **kwargs)
        if is_dataclass(response):
            return enum_to_str(asdict(response))  # type: ignore
        else:
            return response

    return wrapper
