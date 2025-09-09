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
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict

from . import http


@dataclass
class Notification:
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


def send_notification(notification: Notification, token, appid: str):
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
