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

from src.constants import (
    APP_NAME,
    CRASH_REPORT_URL,
)
from src.ut_components import setup

setup(APP_NAME, CRASH_REPORT_URL)
import hashlib
import os
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional
from urllib.parse import urljoin

from src.carddav_client import get_carddav_addressbooks
from src.syncevolution import (
    syncevolution_first_run,
    syncevolution_remove_address_book,
    syncevolution_two_way_sync,
)
from src.ut_components.config import get_app_data_path
from src.ut_components.crash import crash_reporter, get_crash_report, set_crash_report
from src.ut_components.kv import KV
from src.ut_components.utils import dataclass_to_dict, short_string
from src.utils import (
    get_root_url,
    install_background_service_files,
    is_root_url,
    remove_background_service_files,
)


@dataclass
class DefaultServerResponse:
    success: bool
    message: str


@crash_reporter
@dataclass_to_dict
def save_server(url: str, username: str, password: str) -> DefaultServerResponse:
    if is_root_url(url):
        parsed_url = urljoin(url, "/.well-known/carddav")
    else:
        parsed_url = url

    try:
        addressbooks = get_carddav_addressbooks(parsed_url, username, password)
    except Exception as e:
        return DefaultServerResponse(success=False, message=f"Failed to fetch server. Error: {str(e)}")

    if not addressbooks:
        return DefaultServerResponse(success=False, message="Could not find any addressbooks from url")

    with KV() as kv:
        id_ = short_string()
        kv.put_cached(f"server.{id_}.url", parsed_url)
        kv.put_cached(f"server.{id_}.username", username)
        kv.put_cached(f"server.{id_}.password", password)
        kv.put_cached(f"server.{id_}.name", get_root_url(url))
        for addressbook in addressbooks:
            addressbook_id = hashlib.sha1(addressbook.url.encode()).hexdigest()
            kv.put_cached(f"server.{id_}.addressbook.{addressbook_id}.url", addressbook.url)
            kv.put_cached(f"server.{id_}.addressbook.{addressbook_id}.name", addressbook.name)
        kv.commit_cached()

    return DefaultServerResponse(success=True, message="")


@dataclass
class Server:
    id: str
    name: str
    item_count: int
    description: str
    file_path: str


@dataclass
class Servers:
    servers: List[Server]


@crash_reporter
@dataclass_to_dict
def get_servers() -> Servers:
    with KV() as kv:
        partial = kv.get_partial("server") or []
        ids = list(set([x[0].split(".")[1] for x in partial]))
        servers = []
        file_path = os.path.join(get_app_data_path(), "assets/address-book-app-symbolic.svg")
        for id_ in ids:
            name = kv.get(f"server.{id_}.name") or ""
            addressbooks_partial = kv.get_partial(f"server.{id_}.addressbook") or []
            addressbook_ids = list(set([x[0].split(".")[3] for x in addressbooks_partial]))
            servers.append(
                Server(
                    id=id_,
                    name=name,
                    item_count=len(addressbook_ids),
                    description="CardDAV",
                    file_path=file_path,
                )
            )
    return Servers(servers=servers)


@dataclass
class AddressBook:
    id: str
    name: str
    enabled: bool


@dataclass
class ServerDetail:
    addressbooks: List[AddressBook]


@crash_reporter
@dataclass_to_dict
def get_server_detail(server_id: str) -> ServerDetail:
    with KV() as kv:
        partial = kv.get_partial(f"server.{server_id}.addressbook") or []
        addressbook_ids = sorted(list(set([x[0].split(".")[3] for x in partial])))

        addressbooks = []
        for id_ in addressbook_ids:
            addressbook_name = kv.get(f"server.{server_id}.addressbook.{id_}.name") or ""
            enabled = kv.get(f"server.{server_id}.addressbook.{id_}.enabled", False, True) or False
            addressbooks.append(AddressBook(id=id_, name=addressbook_name, enabled=enabled))
    return ServerDetail(addressbooks=addressbooks)


@crash_reporter
def update_address_book_status(server_id: str, addressbook_id: str, enabled: bool):
    with KV() as kv:
        if not enabled:
            addressbook_name = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.name") or ""
            if not addressbook_name:
                return
            syncevolution_remove_address_book(addressbook_name=addressbook_name, addressbook_id=addressbook_id)
            kv.delete(f"server.{server_id}.addressbook.{addressbook_id}.first_run")
        kv.put(f"server.{server_id}.addressbook.{addressbook_id}.enabled", enabled)


@crash_reporter
@dataclass_to_dict
def delete_server(server_id: str) -> DefaultServerResponse:
    with KV() as kv:
        addressbook_partial = kv.get_partial(f"server.{server_id}.addressbook") or []
        addressbook_ids = sorted(list(set([x[0].split(".")[3] for x in addressbook_partial])))
        for addressbook_id in addressbook_ids:
            addressbook_name = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.name") or ""
            if not addressbook_name:
                return DefaultServerResponse(success=False, message="Error deleting address books")
            syncevolution_remove_address_book(addressbook_name=addressbook_name, addressbook_id=addressbook_id)
            kv.delete_partial(f"server.{server_id}.addressbook.{addressbook_id}")
        kv.delete_partial(f"server.{server_id}")
    return DefaultServerResponse(success=True, message="")


@crash_reporter
def persist_token(token: str):
    with KV() as kv:
        kv.put("ut.notification.token", token)


@dataclass
class Configuration:
    background_sync: bool
    crash_report: bool


@crash_reporter
@dataclass_to_dict
def get_configuration() -> Configuration:
    with KV() as kv:
        background_sync = kv.get("configuration.background_sync", False, True) or False
        crash_report = get_crash_report()
    return Configuration(background_sync=background_sync, crash_report=crash_report)


@crash_reporter
def set_background_sync(background_sync: bool) -> DefaultServerResponse:
    with KV() as kv:
        try:
            if background_sync:
                install_background_service_files()
            else:
                remove_background_service_files()
            kv.put("configuration.background_sync", background_sync)
        except Exception as e:
            return DefaultServerResponse(success=False, message=f"Error setting background sync: {str(e)}")
    return DefaultServerResponse(success=True, message="")


def crash_report(crash_report: bool):
    set_crash_report(crash_report)


@crash_reporter
@dataclass_to_dict
def sync_servers() -> DefaultServerResponse:
    success = True
    message = ""
    with KV() as kv:
        lock = kv.get("sync.lock", False)
        if lock:
            return DefaultServerResponse(
                success=False,
                message="Another instance of sync server is running",
            )
        kv.put("sync.lock", True, ttl_seconds=1800)
        server_partial = kv.get_partial("server") or []
        ids = list(set([x[0].split(".")[1] for x in server_partial]))

        for server_id in ids:
            addressbook_partial = kv.get_partial(f"server.{server_id}.addressbook") or []
            addressbook_ids = sorted(list(set([x[0].split(".")[3] for x in addressbook_partial])))
            server_url = kv.get(f"server.{server_id}.url") or ""

            for addressbook_id in addressbook_ids:
                enabled = (
                    kv.get(
                        f"server.{server_id}.addressbook.{addressbook_id}.enabled",
                        False,
                        True,
                    )
                    or False
                )
                if enabled:
                    first_run = kv.get(
                        f"server.{server_id}.addressbook.{addressbook_id}.first_run",
                        True,
                        True,
                    )
                    if first_run:
                        username = kv.get(f"server.{server_id}.username")
                        password = kv.get(f"server.{server_id}.password")
                        addressbook_url = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.url")
                        addressbook_name = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.name")
                        if not addressbook_name or not addressbook_url or not username or not password:
                            return DefaultServerResponse(
                                success=False,
                                message=f"Failed to sync addressbook {addressbook_name}",
                            )
                        result = syncevolution_first_run(
                            addressbook_name=addressbook_name,
                            addressbook_id=addressbook_id,
                            username=username,
                            password=password,
                            server_url=server_url,
                            addressbook_url=addressbook_url,
                        )
                        last_run_type = "first_time"
                        if result.success:
                            kv.put(f"server.{server_id}.addressbook.{addressbook_id}.first_run", False)
                    else:
                        result = syncevolution_two_way_sync(addressbook_id)
                        last_run_type = "regular"

                    last_run_time = int(datetime.now().timestamp())
                    last_run_success = result.success
                    last_run_message = result.message
                    if not last_run_success:
                        success = False
                        message = last_run_message

                    kv.put_cached(
                        f"server.{server_id}.addressbook.{addressbook_id}.last_run.time",
                        last_run_time,
                    )
                    kv.put_cached(
                        f"server.{server_id}.addressbook.{addressbook_id}.last_run.type",
                        last_run_type,
                    )
                    kv.put_cached(
                        f"server.{server_id}.addressbook.{addressbook_id}.last_run.success",
                        last_run_success,
                    )
                    kv.put_cached(
                        f"server.{server_id}.addressbook.{addressbook_id}.last_run.message",
                        last_run_message,
                    )
                    kv.commit_cached()
        kv.put("sync.lock", False, ttl_seconds=1800)
    return DefaultServerResponse(success=success, message=message)


@dataclass
class ServerLog:
    addressbook_name: str
    last_run_time: str
    last_run_type: str
    last_run_success: Optional[bool]
    last_run_message: str


@dataclass
class ServerSyncLogResponse:
    server_logs: List[ServerLog]


@crash_reporter
@dataclass_to_dict
def server_sync_log(server_id: str):
    with KV() as kv:
        addressbook_partial = kv.get_partial(f"server.{server_id}.addressbook") or []
        addressbook_ids = sorted(list(set([x[0].split(".")[3] for x in addressbook_partial])))
        server_logs = []
        for addressbook_id in addressbook_ids:
            addressbook_name = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.name") or ""
            last_run_time = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.last_run.time") or ""
            last_run_type = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.last_run.type") or ""
            last_run_success = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.last_run.success")
            last_run_message = kv.get(f"server.{server_id}.addressbook.{addressbook_id}.last_run.message") or ""

            if not last_run_time:
                continue

            server_logs.append(
                ServerLog(
                    addressbook_name=addressbook_name,
                    last_run_time=datetime.fromtimestamp(last_run_time).isoformat(),
                    last_run_type=last_run_type,
                    last_run_success=last_run_success,
                    last_run_message=last_run_message,
                )
            )
        return ServerSyncLogResponse(server_logs=server_logs)
