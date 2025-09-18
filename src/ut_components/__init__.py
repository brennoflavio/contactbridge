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

from typing import Optional

APP_NAME_ = None
CRASH_REPORT_URL_ = None


def setup(app_name: str, crash_report_url: Optional[str] = None):
    """
    Initialize the UT Components library with application configuration.

    This function must be called on each python file you're gonna import library components
    the library with essential application information. It sets up global
    variables that will be used by various components throughout the library
    for identifying the application and handling crash reports.

    Args:
        app_name (str): The name of your Ubuntu Touch application. This is used
            for identifying the app in logs, crash reports, and other components.
        crash_report_url (Optional[str]): URL endpoint for submitting crash reports.
            If provided, components can send crash data to this URL for debugging.
            Defaults to None if crash reporting is not needed.

    Example:
        >>> from src.ut_components import setup
        >>>
        >>> # Basic setup without crash reporting
        >>> setup(app_name="MyUTApp")
        >>>
        >>> # Setup with crash reporting enabled
        >>> setup(
        ...     app_name="MyUTApp",
        ...     crash_report_url="https://api.myapp.com/crashes"
        ... )
    """
    global APP_NAME_, CRASH_REPORT_URL_
    APP_NAME_ = app_name
    CRASH_REPORT_URL_ = crash_report_url
