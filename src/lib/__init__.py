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

APP_NAME_ = None
CRASH_REPORT_URL_ = None


def setup(app_name: str, crash_report_url: str):
    global APP_NAME_, CRASH_REPORT_URL_
    APP_NAME_ = app_name
    CRASH_REPORT_URL_ = crash_report_url
