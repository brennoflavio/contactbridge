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

import json
import os
import sqlite3
from datetime import datetime, timedelta
from typing import Any, List, Optional, Tuple

from .config import get_config_path


class KV:
    """
    A persistent key-value storage system with TTL (time-to-live) support.

    The KV class provides a simple yet powerful interface for storing and retrieving
    data persistently using SQLite as the backend. It supports automatic expiration
    of entries through TTL, batch operations for performance, and prefix-based queries.
    All values are automatically serialized to JSON for storage.

    Features:
        - Persistent storage using SQLite
        - TTL support for automatic expiration
        - Batch operations for improved performance
        - Prefix-based queries and deletions
        - Context manager support for automatic cleanup
        - JSON serialization for complex data types

    Example:
        >>> from src.ut_components.kv import KV
        >>>
        >>> # Basic usage
        >>> kv = KV()
        >>> kv.put("user:123", {"name": "John", "age": 30})
        >>> user = kv.get("user:123")
        >>> print(user)  # {"name": "John", "age": 30}
        >>> kv.close()
        >>>
        >>> # Using context manager
        >>> with KV() as kv:
        ...     kv.put("config:theme", "dark", ttl_seconds=3600)
        ...     theme = kv.get("config:theme", default="light")
        >>>
        >>> # Batch operations
        >>> with KV() as kv:
        ...     for i in range(1000):
        ...         kv.put_cached(f"item:{i}", {"value": i})
        ...     kv.commit_cached()  # Single transaction for all items
    """

    def __init__(self) -> None:
        """
        Initialize the KV storage system and create the database if needed.

        Creates a SQLite database in the application's config directory
        (as determined by get_config_path()) and sets up the necessary
        table structure for key-value storage with TTL support.

        The database file is created at: {config_path}/kv.db

        Example:
            >>> from src.ut_components.kv import KV
            >>>
            >>> # Create a new KV instance
            >>> kv = KV()
            >>>
            >>> # Use it to store data
            >>> kv.put("my_key", "my_value")
            >>> kv.close()
        """
        config_folder = get_config_path()
        os.makedirs(config_folder, exist_ok=True)
        self.conn = sqlite3.connect(os.path.join(config_folder, "kv.db"))
        self.cursor = self.conn.cursor()
        self.cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS kv (
                key TEXT PRIMARY KEY,
                value TEXT default '',
                ttl integer DEFAULT NULL
            )
        """
        )
        self.conn.commit()
        self.cache_values = []
        self.cache_row_count = 0

    def _encode_value(self, value: Any) -> str:
        return json.dumps({"value": value})

    def _decode_value(self, value: str) -> Any:
        return json.loads(value).get("value", None)

    def put(self, key: str, value: Any, ttl_seconds: Optional[int] = None) -> None:
        """
        Store a key-value pair in the database with optional TTL.

        Inserts or updates a key-value pair in the storage. The value is
        automatically serialized to JSON before storage, allowing you to
        store complex Python objects (dicts, lists, etc.).

        Args:
            key (str): The unique identifier for the value. If the key already
                exists, its value will be replaced.
            value (Any): The value to store. Can be any JSON-serializable Python
                object (str, int, float, bool, dict, list, None).
            ttl_seconds (Optional[int]): Time-to-live in seconds. If provided,
                the entry will automatically expire after this duration.
                Defaults to None (no expiration).

        Example:
            >>> kv = KV()
            >>>
            >>> # Store simple value
            >>> kv.put("username", "john_doe")
            >>>
            >>> # Store complex object
            >>> kv.put("user:profile", {
            ...     "name": "John Doe",
            ...     "email": "john@example.com",
            ...     "preferences": ["dark_mode", "notifications"]
            ... })
            >>>
            >>> # Store with expiration (1 hour)
            >>> kv.put("session:token", "abc123xyz", ttl_seconds=3600)
            >>>
            >>> kv.close()
        """
        if ttl_seconds:
            ttl = int((datetime.now() + timedelta(seconds=ttl_seconds)).timestamp())
        else:
            ttl = None

        self.cursor.execute(
            """
            INSERT OR REPLACE INTO kv (key, value, ttl) VALUES (?, ?, ?)
        """,
            (key, self._encode_value(value), ttl),
        )
        self.conn.commit()

    def get(
        self,
        key: str,
        default: Optional[Any] = None,
        save_default_if_not_set: bool = False,
    ) -> Optional[Any]:
        """
        Retrieve a value from the database by its key.

        Fetches the value associated with the given key. If the key doesn't
        exist or has expired (TTL exceeded), returns the default value.
        Optionally saves the default value if the key is not found.

        Args:
            key (str): The key to look up in the storage.
            default (Optional[Any]): The value to return if the key is not found
                or has expired. Defaults to None.
            save_default_if_not_set (bool): If True and the key is not found,
                saves the default value under this key. Useful for initializing
                settings with defaults. Defaults to False.

        Returns:
            Optional[Any]: The stored value if found and not expired, otherwise
            the default value. The value is automatically deserialized from JSON.

        Example:
            >>> kv = KV()
            >>>
            >>> # Basic retrieval
            >>> kv.put("greeting", "Hello, World!")
            >>> msg = kv.get("greeting")
            >>> print(msg)  # "Hello, World!"
            >>>
            >>> # With default value
            >>> theme = kv.get("theme", default="light")
            >>> print(theme)  # "light" (if not set)
            >>>
            >>> # Save default if not set
            >>> lang = kv.get("language", default="en", save_default_if_not_set=True)
            >>> # Now "language" is saved with value "en"
            >>>
            >>> # Expired values return default
            >>> kv.put("temp", "data", ttl_seconds=1)
            >>> import time
            >>> time.sleep(2)
            >>> val = kv.get("temp", default="expired")
            >>> print(val)  # "expired"
            >>>
            >>> kv.close()
        """
        now_seconds = int(datetime.now().timestamp())

        self.cursor.execute(
            """
            SELECT value FROM kv WHERE key = ? AND (ttl IS NULL OR ttl > ?)
        """,
            (key, now_seconds),
        )
        result = self.cursor.fetchone()
        if result:
            result = result[0]
        else:
            result = None

        if not result:
            if save_default_if_not_set:
                self.put(key, default)
            return default

        return self._decode_value(result)

    def get_partial(self, beginning: str) -> List[Tuple[str, Any]]:
        """
        Retrieve all key-value pairs where keys start with a given prefix.

        Performs a prefix search on keys and returns all matching entries
        that haven't expired. Results are sorted by value (in JSON string form).
        This is useful for implementing features like autocomplete, finding
        all items in a category, or retrieving related configuration options.

        Args:
            beginning (str): The prefix to search for. All keys starting with
                this string will be returned.

        Returns:
            List[Tuple[str, Any]]: A list of tuples where each tuple contains
            (key, value). Values are automatically deserialized from JSON.
            Returns empty list if no matches found.

        Example:
            >>> kv = KV()
            >>>
            >>> # Store related data with common prefix
            >>> kv.put("user:123:name", "Alice")
            >>> kv.put("user:123:email", "alice@example.com")
            >>> kv.put("user:123:age", 30)
            >>> kv.put("user:456:name", "Bob")
            >>>
            >>> # Get all data for user 123
            >>> user_data = kv.get_partial("user:123:")
            >>> for key, value in user_data:
            ...     print(f"{key} = {value}")
            >>> # Output:
            >>> # user:123:age = 30
            >>> # user:123:email = alice@example.com
            >>> # user:123:name = Alice
            >>>
            >>> # Get all users
            >>> all_users = kv.get_partial("user:")
            >>> print(len(all_users))  # 4 (all user fields)
            >>>
            >>> kv.close()
        """
        now_seconds = int(datetime.now().timestamp())

        self.cursor.execute(
            """
            SELECT key, value FROM kv WHERE key LIKE ? || '%' AND (ttl IS NULL OR ttl > ?) ORDER BY value
        """,
            (beginning, now_seconds),
        )
        result = self.cursor.fetchall()
        return [(x[0], self._decode_value(x[1])) for x in result]

    def delete(self, key: str) -> None:
        """
        Delete a specific key-value pair from the database.

        Removes the entry associated with the given key from storage.
        If the key doesn't exist, the operation completes without error.

        Args:
            key (str): The key of the entry to delete.

        Example:
            >>> kv = KV()
            >>>
            >>> # Store and delete a value
            >>> kv.put("temp_data", "temporary")
            >>> print(kv.get("temp_data"))  # "temporary"
            >>> kv.delete("temp_data")
            >>> print(kv.get("temp_data"))  # None
            >>>
            >>> # Deleting non-existent key is safe
            >>> kv.delete("non_existent_key")  # No error
            >>>
            >>> kv.close()
        """
        self.cursor.execute(
            """
            DELETE FROM kv WHERE key = ?
        """,
            (key,),
        )
        self.conn.commit()

    def delete_partial(self, beginning: str):
        """
        Delete all key-value pairs where keys start with a given prefix.

        Performs a bulk deletion of all entries whose keys match the specified
        prefix. This is useful for cleaning up related data, removing all items
        in a category, or clearing cache entries with a common prefix.

        Args:
            beginning (str): The prefix to match. All keys starting with
                this string will be deleted.

        Example:
            >>> kv = KV()
            >>>
            >>> # Store related data
            >>> kv.put("cache:user:123", {"name": "Alice"})
            >>> kv.put("cache:user:456", {"name": "Bob"})
            >>> kv.put("cache:product:789", {"title": "Widget"})
            >>> kv.put("settings:theme", "dark")
            >>>
            >>> # Delete all user cache entries
            >>> kv.delete_partial("cache:user:")
            >>>
            >>> # Only product cache and settings remain
            >>> print(kv.get("cache:user:123"))  # None
            >>> print(kv.get("cache:product:789"))  # {"title": "Widget"}
            >>>
            >>> # Delete all cache entries
            >>> kv.delete_partial("cache:")
            >>> print(kv.get("cache:product:789"))  # None
            >>> print(kv.get("settings:theme"))  # "dark" (still exists)
            >>>
            >>> kv.close()
        """
        self.cursor.execute(
            """
            DELETE FROM kv WHERE key like ? || '%'
        """,
            (beginning,),
        )
        self.conn.commit()

    def close(self) -> None:
        """
        Close the database connection and commit any pending changes.

        Ensures all pending transactions are committed and properly closes
        the SQLite database connection. This should be called when you're
        done using the KV instance to free up resources.

        Note: If using the KV class as a context manager (with statement),
        this method is called automatically.

        Example:
            >>> kv = KV()
            >>> kv.put("data", "value")
            >>> kv.close()  # Ensures data is saved and connection is closed
            >>>
            >>> # Or use context manager for automatic cleanup
            >>> with KV() as kv:
            ...     kv.put("data", "value")
            >>> # close() is called automatically here
        """
        self.conn.commit()
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def put_cached(self, key: str, value: Any, ttl_seconds: Optional[int] = None) -> None:
        """
        Add a key-value pair to the cache for batch insertion.

        Instead of immediately writing to the database, this method stores
        the key-value pair in memory. Multiple cached entries can then be
        committed together in a single transaction using commit_cached(),
        significantly improving performance for bulk insertions.

        Args:
            key (str): The unique identifier for the value.
            value (Any): The value to store. Can be any JSON-serializable Python
                object (str, int, float, bool, dict, list, None).
            ttl_seconds (Optional[int]): Time-to-live in seconds. If provided,
                the entry will automatically expire after this duration.
                Defaults to None (no expiration).

        Example:
            >>> kv = KV()
            >>>
            >>> # Bulk insert with caching (fast)
            >>> for i in range(10000):
            ...     kv.put_cached(f"item:{i}", {"value": i, "squared": i**2})
            >>> kv.commit_cached()  # Single transaction for all 10000 items
            >>>
            >>> # Compare with regular put (slower for bulk)
            >>> for i in range(10000, 20000):
            ...     kv.put(f"item:{i}", {"value": i})  # 10000 separate transactions
            >>>
            >>> # Cache with TTL
            >>> for i in range(100):
            ...     kv.put_cached(f"temp:{i}", i, ttl_seconds=300)  # 5 minutes TTL
            >>> kv.commit_cached()
            >>>
            >>> kv.close()
        """
        if ttl_seconds:
            ttl = int((datetime.now() + timedelta(seconds=ttl_seconds)).timestamp())
        else:
            ttl = None

        self.cache_values.extend([key, self._encode_value(value), ttl])
        self.cache_row_count += 1

    def commit_cached(self) -> None:
        """
        Commit all cached key-value pairs to the database in a single transaction.

        Writes all entries added via put_cached() to the database in one
        efficient bulk operation. After committing, the cache is cleared.
        If no cached entries exist, this method does nothing.

        This method is essential for achieving high performance when inserting
        many entries, as it reduces the overhead of individual transactions.

        Example:
            >>> kv = KV()
            >>>
            >>> # Add multiple entries to cache
            >>> kv.put_cached("user:1", {"name": "Alice", "score": 100})
            >>> kv.put_cached("user:2", {"name": "Bob", "score": 85})
            >>> kv.put_cached("user:3", {"name": "Charlie", "score": 92})
            >>>
            >>> # Nothing written to database yet
            >>> print(kv.get("user:1"))  # None
            >>>
            >>> # Commit all at once
            >>> kv.commit_cached()
            >>>
            >>> # Now data is available
            >>> print(kv.get("user:1"))  # {"name": "Alice", "score": 100}
            >>>
            >>> # Cache is now empty, safe to call again
            >>> kv.commit_cached()  # Does nothing
            >>>
            >>> kv.close()
        """
        if not self.cache_values:
            return

        values = ",".join(["(?, ?, ?)" for _ in range(self.cache_row_count)])

        sql = f"""
            INSERT OR REPLACE INTO kv (key, value, ttl) VALUES {values}
        """

        self.cursor.execute(sql, self.cache_values)
        self.conn.commit()
        self.cache_values = []
        self.cache_row_count = 0
