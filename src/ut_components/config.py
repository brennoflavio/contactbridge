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

import os

from . import APP_NAME_


def get_config_path() -> str:
    """
    Get the XDG-compliant configuration directory path for the application.

    This function returns the standard configuration directory where the
    application should store its configuration files. It follows the XDG
    Base Directory specification, ensuring your app's configs are stored
    in the appropriate system location.

    The function respects the XDG_CONFIG_HOME environment variable if set,
    otherwise defaults to ~/.config. The application name (set via setup())
    is appended to create an app-specific configuration directory.

    Returns:
        str: The absolute path to the application's configuration directory.
             Typically ~/.config/{app_name} or $XDG_CONFIG_HOME/{app_name}

    Raises:
        AssertionError: If setup() has not been called to initialize APP_NAME_

    Example:
        >>> from src.ut_components import setup
        >>> from src.ut_components.config import get_config_path
        >>>
        >>> # Initialize the library with your app name
        >>> setup(app_name="myapp.example")
        >>>
        >>> # Get the config directory path
        >>> config_dir = get_config_path()
        >>> print(config_dir)
        /home/user/.config/myapp.example
        >>>
        >>> # Use it to store configuration files
        >>> config_file = os.path.join(config_dir, "settings.json")
    """
    assert APP_NAME_
    xdg_config = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(xdg_config, APP_NAME_)


def get_cache_path() -> str:
    """
    Get the XDG-compliant cache directory path for the application.

    This function returns the standard cache directory where the
    application should store temporary cache files. It follows the XDG
    Base Directory specification, ensuring your app's cache is stored
    in the appropriate system location for temporary/regenerable data.

    The function respects the XDG_CACHE_HOME environment variable if set,
    otherwise defaults to ~/.cache. The application name (set via setup())
    is appended to create an app-specific cache directory.

    Returns:
        str: The absolute path to the application's cache directory.
             Typically ~/.cache/{app_name} or $XDG_CACHE_HOME/{app_name}

    Raises:
        AssertionError: If setup() has not been called to initialize APP_NAME_

    Example:
        >>> from src.ut_components import setup
        >>> from src.ut_components.config import get_cache_path
        >>>
        >>> # Initialize the library with your app name
        >>> setup(app_name="myapp.example")
        >>>
        >>> # Get the cache directory path
        >>> cache_dir = get_cache_path()
        >>> print(cache_dir)
        /home/user/.cache/myapp.example
        >>>
        >>> # Use it to store temporary/cache files
        >>> thumbnail_cache = os.path.join(cache_dir, "thumbnails")
        >>> downloaded_file = os.path.join(cache_dir, "temp_download.dat")
    """
    assert APP_NAME_
    xdg_cache = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
    return os.path.join(xdg_cache, APP_NAME_)


def get_app_data_path() -> str:
    """
    Get the application's installation directory path.

    This function returns the path to the directory where the application
    is installed on Ubuntu Touch. This is typically used to access
    read-only application resources like QML files, icons, assets, and
    other bundled data that ships with the application package.

    The function reads the APP_DIR environment variable, which is
    automatically set by the Ubuntu Touch application confinement system
    when the app is launched.

    Returns:
        str: The absolute path to the application's installation directory.
             On Ubuntu Touch, this is typically something like
             /opt/click.ubuntu.com/{app_name}/current/

    Raises:
        Exception: If the APP_DIR environment variable is not set, which
                   usually means the app is not running in a proper Ubuntu
                   Touch confined environment.

    Example:
        >>> from src.ut_components.config import get_app_data_path
        >>>
        >>> # Get the app installation directory
        >>> app_dir = get_app_data_path()
        >>> print(app_dir)
        /opt/click.ubuntu.com/myapp.example/1.0.0/
        >>>
        >>> # Access bundled resources
        >>> qml_dir = os.path.join(app_dir, "qml")
        >>> icon_path = os.path.join(app_dir, "assets", "icon.svg")
        >>> main_qml = os.path.join(app_dir, "qml", "Main.qml")
    """
    path = os.environ.get("APP_DIR")
    if not path:
        raise Exception("could not find path")
    return path
