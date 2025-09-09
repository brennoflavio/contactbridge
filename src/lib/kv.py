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

import json
import os
import sqlite3
from datetime import datetime, timedelta
from typing import Any, List, Optional, Tuple

from .config import get_config_path


class KV:
    def __init__(self) -> None:
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

    def get_partial(self, beginning: str) -> Optional[List[Tuple]]:
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
        self.cursor.execute(
            """
            DELETE FROM kv WHERE key = ?
        """,
            (key,),
        )
        self.conn.commit()

    def delete_partial(self, beginning: str) -> Optional[List[Tuple]]:
        self.cursor.execute(
            """
            DELETE FROM kv WHERE key like ? || '%'
        """,
            (beginning,),
        )
        self.conn.commit()

    def close(self) -> None:
        self.conn.commit()
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    def put_cached(self, key: str, value: Any, ttl_seconds: Optional[int] = None) -> None:
        if ttl_seconds:
            ttl = int((datetime.now() + timedelta(seconds=ttl_seconds)).timestamp())
        else:
            ttl = None

        self.cache_values.extend([key, self._encode_value(value), ttl])
        self.cache_row_count += 1

    def commit_cached(self) -> None:
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
