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
import hashlib
import json
from typing import Any, Callable

from .kv import KV


def hash_function_name(func: Callable) -> str:
    """
    Generate a unique hash identifier for a function based on its name and module.

    This helper function creates a SHA1 hash of the function's fully qualified name
    (module + function name) to uniquely identify functions in the cache system.
    It ensures that functions with the same name in different modules get
    different cache keys.

    Args:
        func (Callable): The function object to generate a hash for.

    Returns:
        str: A hexadecimal SHA1 hash string representing the function's unique identifier.

    Example:
        >>> def my_function():
        ...     pass
        >>> hash_id = hash_function_name(my_function)
        >>> print(hash_id)  # e.g., "a3c65c2974270fd093ee8..."
    """
    function_name = f"{func.__module__}.{func.__name__}"
    return hashlib.sha1(f"{function_name}".encode()).hexdigest()


def hash_function_args(args, kwargs) -> str:
    """
    Generate a unique hash identifier for function arguments.

    This helper function creates a SHA1 hash of the function's arguments
    (both positional and keyword arguments) by JSON-serializing them.
    This allows the cache system to differentiate between different function
    calls with different arguments.

    Args:
        args: Positional arguments passed to the function.
        kwargs: Keyword arguments passed to the function.

    Returns:
        str: A hexadecimal SHA1 hash string representing the arguments' unique identifier.

    Note:
        Arguments must be JSON-serializable. Non-serializable objects like
        custom classes, datetime objects, or sets will cause this function to fail.

    Example:
        >>> hash_id = hash_function_args(("hello", 42), {"key": "value"})
        >>> print(hash_id)  # e.g., "b7c4d8f2a91e3..."
    """
    encoded_args = f"{json.dumps(args, sort_keys=True)}-{json.dumps(kwargs, sort_keys=True)}"
    return hashlib.sha1(f"{encoded_args}".encode()).hexdigest()


def memoize(ttl_seconds: int):
    """
    Decorator factory for caching function results with time-to-live (TTL).

    This decorator implements memoization, which caches the results of expensive
    function calls and returns the cached result when the same inputs occur again.
    The cache automatically expires after the specified TTL period, ensuring data
    freshness. This is particularly useful for functions that perform expensive
    computations, database queries, or API calls.

    The decorator uses a key-value store to persist cache across application
    restarts and creates unique cache keys based on the function name and arguments.

    Args:
        ttl_seconds (int): Time-to-live for cached results in seconds. After this
            period, the cache expires and the function will be executed again.

    Returns:
        Callable: A decorator function that can be applied to any function.

    Note:
        - Function arguments must be JSON-serializable for caching to work.
        - Cached results are stored in a persistent KV store.
        - Each unique combination of arguments creates a separate cache entry.

    Example:
        >>> from src.ut_components.memoize import memoize
        >>> import time
        >>>
        >>> @memoize(ttl_seconds=3600)  # Cache for 1 hour
        >>> def expensive_api_call(user_id: str, endpoint: str):
        ...     # Simulating an expensive operation
        ...     time.sleep(2)
        ...     return f"Data for user {user_id} from {endpoint}"
        >>>
        >>> # First call takes 2 seconds
        >>> result1 = expensive_api_call("user123", "/profile")
        >>>
        >>> # Second call with same arguments returns instantly from cache
        >>> result2 = expensive_api_call("user123", "/profile")
        >>>
        >>> # Different arguments create a new cache entry
        >>> result3 = expensive_api_call("user456", "/profile")
    """

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
    """
    Clear all cached entries for a specific memoized function.

    This function removes all cached results for the specified function,
    regardless of what arguments were used when calling it. This is useful
    when you need to invalidate the cache for a function, such as after
    updating underlying data or when testing.

    The function uses partial key deletion to remove all cache entries
    that match the function's hashed name pattern.

    Args:
        function (Callable): The memoized function whose cache should be cleared.
            Must be the actual function object that was decorated with @memoize.

    Example:
        >>> from src.ut_components.memoize import memoize, delete_memoized
        >>>
        >>> @memoize(ttl_seconds=3600)
        >>> def get_user_data(user_id: str):
        ...     # Expensive database query
        ...     return fetch_from_database(user_id)
        >>>
        >>> # Use the function normally
        >>> data1 = get_user_data("user123")  # Fetches from database
        >>> data2 = get_user_data("user123")  # Returns from cache
        >>>
        >>> # Clear all cached results for this function
        >>> delete_memoized(get_user_data)
        >>>
        >>> # Next call will fetch from database again
        >>> data3 = get_user_data("user123")  # Fetches from database
    """
    hashed_function_name = hash_function_name(function)
    with KV() as kv:
        kv.delete_partial(f"memoize.{hashed_function_name}")
