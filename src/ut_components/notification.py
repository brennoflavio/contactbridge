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
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict

from . import http


@dataclass
class Notification:
    """
    Represents a push notification for Ubuntu Touch applications.

    This dataclass encapsulates all properties needed to create and send
    push notifications through the Ubuntu Push Notification Service.
    It provides methods for serialization to the required format.

    Attributes:
        icon (str): The icon name or path to display with the notification.
            Should be a valid icon from the system theme or app resources.
        summary (str): The title or summary text shown in the notification header.
        body (str): The main content/message of the notification.
        popup (bool): Whether to display the notification as a popup overlay.
        persist (bool): Whether the notification should persist in the notification
            drawer until explicitly dismissed by the user.
        vibrate (bool): Whether to trigger device vibration when the notification
            is received (subject to user settings).
        sound (bool): Whether to play a notification sound when received
            (subject to user settings).

    Example:
        >>> from src.ut_components.notification import Notification
        >>>
        >>> # Create a simple notification
        >>> notification = Notification(
        ...     icon="dialog-information",
        ...     summary="New Message",
        ...     body="You have received a new message from John",
        ...     popup=True,
        ...     persist=True,
        ...     vibrate=True,
        ...     sound=True
        ... )
        >>>
        >>> # Convert to Ubuntu Push format
        >>> push_data = notification.dict()
        >>> # Or get JSON string
        >>> json_str = notification.dump()
    """

    icon: str
    summary: str
    body: str
    popup: bool
    persist: bool
    vibrate: bool
    sound: bool

    def dict(self) -> Dict:
        return {
            "notification": {
                "card": {
                    "icon": self.icon,
                    "summary": self.summary,
                    "body": self.body,
                    "popup": self.popup,
                    "persist": self.persist,
                },
                "vibrate": self.vibrate,
                "sound": self.sound,
            }
        }

    def dump(self) -> str:
        return json.dumps(self.dict())


def parse_notification(raw_notification: str) -> Notification:
    """
    Parse a JSON string into a Notification object.

    Deserializes a JSON-formatted push notification string (typically received
    from the Ubuntu Push Notification Service) into a Notification dataclass
    instance. Provides sensible defaults for any missing fields.

    Args:
        raw_notification (str): A JSON string containing the notification data
            in Ubuntu Push format. Should have a structure with "notification"
            containing "card" and vibrate/sound settings.

    Returns:
        Notification: A Notification object populated with the parsed data.
            Missing fields will use defaults: icon="notification", empty strings
            for text fields, and False for boolean flags.

    Example:
        >>> from src.ut_components.notification import parse_notification
        >>> import json
        >>>
        >>> # Parse a notification from JSON
        >>> json_data = '''
        ... {
        ...     "notification": {
        ...         "card": {
        ...             "icon": "message-new",
        ...             "summary": "Alert",
        ...             "body": "Important update available",
        ...             "popup": true,
        ...             "persist": false
        ...         },
        ...         "vibrate": true,
        ...         "sound": false
        ...     }
        ... }
        ... '''
        >>> notification = parse_notification(json_data)
        >>> print(notification.summary)  # Output: "Alert"
    """
    data = json.loads(raw_notification)
    notification = data.get("notification", {})
    card = notification.get("card", {})
    return Notification(
        icon=card.get("icon", "notification"),
        summary=card.get("summary", ""),
        body=card.get("body", ""),
        popup=card.get("popup", False),
        persist=card.get("persist", False),
        vibrate=notification.get("vibrate", False),
        sound=notification.get("sound", False),
    )


def send_notification(notification: Notification, token: str, appid: str):
    """
    Send a push notification through the Ubuntu Push Notification Service.

    Transmits a notification to a specific device using the Ubuntu Push
    infrastructure. The notification will be delivered to the device
    identified by the provided token, for the specified application.
    The notification expires after 10 minutes if not delivered.

    Args:
        notification (Notification): The notification object containing all
            the message details, formatting, and behavior settings.
        token (str): The unique push token identifying the target device.
            This token is obtained during the app's push registration process.
        appid (str): The application identifier in the format "appname_version"
            or as registered with the Ubuntu Push service.

    Raises:
        requests.exceptions.HTTPError: If the push service returns an error
            status code (4xx or 5xx).
        requests.exceptions.RequestException: For network-related errors
            during the API call.

    Example:
        >>> from src.ut_components.notification import Notification, send_notification
        >>>
        >>> # Create and send a notification
        >>> notification = Notification(
        ...     icon="alarm-clock",
        ...     summary="Reminder",
        ...     body="Your meeting starts in 5 minutes",
        ...     popup=True,
        ...     persist=False,
        ...     vibrate=True,
        ...     sound=True
        ... )
        >>>
        >>> # Send to a specific device
        >>> send_notification(
        ...     notification=notification,
        ...     token="abc123def456",  # Device push token
        ...     appid="myapp.developer_1.0"
        ... )
    """
    url = "https://push.ubports.com/notify"
    expire_at = datetime.utcnow() + timedelta(minutes=10)
    data = {
        "appid": appid,
        "expire_on": expire_at.isoformat() + "Z",
        "token": token,
        "data": notification.dict(),
    }
    response = http.post(url, json=data)
    response.raise_for_status()
