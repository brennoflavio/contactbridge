#!/usr/bin/python3
"""
Copyright (C) 2025  Brenno Flávio de Almeida

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3.

contactbridge is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

from src.constants import APP_ID, APP_NAME, CRASH_REPORT_URL
from src.lib import setup

setup(APP_NAME, CRASH_REPORT_URL)

from src.lib.kv import KV
from src.lib.notification import Notification, send_notification
from src.server import sync_servers


def sync_library():
    try:
        response = sync_servers()
    except Exception as e:
        with KV() as kv:
            token = kv.get("ut.notification.token")
            if token:
                notification = Notification(
                    icon="address-book-app-symbolic",
                    summary="Sync failed",
                    body=f"Error: {str(e)[-100:]}",
                    popup=True,
                    persist=True,
                    vibrate=False,
                    sound=False,
                )
                send_notification(notification, token, APP_ID)
        raise
    success = response.get("success")
    if not success:
        message = response.get("message", "")
        with KV() as kv:
            token = kv.get("ut.notification.token")
            if token:
                notification = Notification(
                    icon="address-book-app-symbolic",
                    summary="Sync failed",
                    body=f"Error: {message[-100:]}",
                    popup=True,
                    persist=True,
                    vibrate=False,
                    sound=False,
                )
                send_notification(notification, token, APP_ID)


if __name__ == "__main__":
    sync_library()
