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

import os
import shutil
import subprocess
from urllib.parse import urlparse

from constants import SYNC_SERVICE_DEST_PATH, TIMER_SERVICE_DEST_PATH
from src.lib.config import get_app_data_path


def run_subprocess(args):
    return subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


def is_root_url(url):
    parsed = urlparse(url)
    return parsed.path in ("", "/")


def get_root_url(url):
    parsed = urlparse(url)
    return parsed.netloc


def reload_systemd(start: bool):
    result = run_subprocess(["systemctl", "--user", "daemon-reload"])
    if result.returncode != 0:
        raise ValueError("Error reloading systemd user daemon:", result.stdout)

    if start:
        result = run_subprocess(["systemctl", "--user", "start", "contactbridge-timer.timer"])
        if result.returncode != 0:
            raise ValueError("Error starting systemd user daemon:", result.stdout)

        result = run_subprocess(["systemctl", "--user", "enable", "contactbridge-timer.timer"])
        if result.returncode != 0:
            raise ValueError("Error enabling systemd user daemon:", result.stdout)


def install_background_service_files():
    sync_service_local_path = os.path.join(get_app_data_path(), "src/services/contactbridge-sync.service")
    timer_service_local_path = os.path.join(get_app_data_path(), "src/services/contactbridge-timer.timer")

    if os.path.exists(SYNC_SERVICE_DEST_PATH):
        os.remove(SYNC_SERVICE_DEST_PATH)

    if os.path.exists(TIMER_SERVICE_DEST_PATH):
        os.remove(TIMER_SERVICE_DEST_PATH)

    shutil.copy(sync_service_local_path, SYNC_SERVICE_DEST_PATH)
    shutil.copy(timer_service_local_path, TIMER_SERVICE_DEST_PATH)

    reload_systemd(start=True)


def remove_background_service_files():
    if os.path.exists(SYNC_SERVICE_DEST_PATH):
        os.remove(SYNC_SERVICE_DEST_PATH)

    if os.path.exists(TIMER_SERVICE_DEST_PATH):
        os.remove(TIMER_SERVICE_DEST_PATH)

    reload_systemd(start=False)
