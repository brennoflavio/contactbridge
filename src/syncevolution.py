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

from dataclasses import dataclass
from typing import Any, Callable, List

from src.utils import run_subprocess

# https://gist.github.com/vanyasem/379095d25ac350676fc70c42efe17c8c
# https://leste.maemo.org/Sync


def shorten_sha_id(sha_id: str) -> str:
    return sha_id[0:7]


def create_database(addressbook_name: str):
    args = [
        "syncevolution",
        "--create-database",
        "backend=evolution-contacts",
        f"database={addressbook_name}",
    ]
    return run_subprocess(args)


def create_server_configuration(addressbook_id: str, username: str, password: str, server_url: str):
    args = [
        "syncevolution",
        "--configure",
        "--template",
        "webdav",
        f"username={username}",
        f"password={password}",
        f"syncURL={server_url}",
        f"target-config@{shorten_sha_id(addressbook_id)}",
    ]
    return run_subprocess(args)


def create_addressbook_configuration(addressbook_id: str, addressbook_url: str):
    args = [
        "syncevolution",
        "--configure",
        "--template",
        "webdav",
        f"database={addressbook_url}",
        "backend=carddav",
        f"target-config@{shorten_sha_id(addressbook_id)}",
        shorten_sha_id(addressbook_id),
    ]
    return run_subprocess(args)


def create_local_configuration(addressbook_id: str):
    args = [
        "syncevolution",
        "--configure",
        "--template",
        "SyncEvolution_Client",
        "sync=none",
        f"syncURL=local://@{shorten_sha_id(addressbook_id)}",
        "username=",
        "password=",
        shorten_sha_id(addressbook_id),
    ]
    return run_subprocess(args)


def create_two_way_configuration(addressbook_name: str, addressbook_id: str):
    args = [
        "syncevolution",
        "--configure",
        "sync=two-way",
        "backend=evolution-contacts",
        f"database={addressbook_name}",
        shorten_sha_id(addressbook_id),
        shorten_sha_id(addressbook_id),
    ]
    return run_subprocess(args)


def run_first_sync(addressbook_id: str):
    args = [
        "syncevolution",
        "--sync",
        "refresh-from-remote",
        shorten_sha_id(addressbook_id),
        shorten_sha_id(addressbook_id),
    ]
    return run_subprocess(args)


def delete_database(addressbook_name: str):
    args = [
        "syncevolution",
        "--remove-database",
        "backend=evolution-contacts",
        f"database={addressbook_name}",
    ]
    return run_subprocess(args)


def delete_server_configuration(addressbook_id: str):
    args = ["syncevolution", "--remove", shorten_sha_id(addressbook_id)]
    return run_subprocess(args)


def delete_target_configuration(addressbook_id: str):
    args = [
        "syncevolution",
        "--remove",
        f"target-config@{shorten_sha_id(addressbook_id)}",
    ]
    return run_subprocess(args)


def two_way_sync(addressbook_id: str):
    args = [
        "syncevolution",
        "--sync",
        "two-way",
        shorten_sha_id(addressbook_id),
        shorten_sha_id(addressbook_id),
    ]
    return run_subprocess(args)


def syncevolution_remove_address_book(addressbook_name: str, addressbook_id: str):
    target_config_response = delete_target_configuration(addressbook_id)
    if target_config_response.returncode != 0:
        err_string = target_config_response.stdout
        if "no such configuration" not in err_string.lower():
            raise ValueError(f"Failed to delete target config for address book {addressbook_id}")

    server_config_response = delete_server_configuration(addressbook_id)
    if server_config_response.returncode != 0:
        err_string = server_config_response.stdout
        if "no such configuration" not in err_string.lower():
            raise ValueError(f"Failed to delete target config for address book {addressbook_id}")

    database_response = delete_database(addressbook_name)
    if database_response.returncode != 0:
        err_string = database_response.stdout
        if "database not found" not in err_string.lower():
            raise ValueError(f"Failed to delete target config for address book {addressbook_id}")


@dataclass
class SyncResponse:
    success: bool
    message: str


def run_step(
    addressbook_name: str,
    addressbook_id: str,
    step_func: Callable,
    step_args: List[Any],
):
    try:
        response = step_func(*step_args)
        if response.returncode != 0:
            syncevolution_remove_address_book(addressbook_name, addressbook_id)
            return SyncResponse(success=False, message=response.stdout)
        return SyncResponse(success=True, message=response.stdout)
    except Exception as e:
        syncevolution_remove_address_book(addressbook_name, addressbook_id)
        return SyncResponse(success=False, message=str(e))


def syncevolution_first_run(
    addressbook_name: str,
    addressbook_id: str,
    username: str,
    password: str,
    server_url: str,
    addressbook_url: str,
) -> SyncResponse:
    result = run_step(addressbook_name, addressbook_id, create_database, [addressbook_name])
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"create_database failed with error: {result.message}",
        )

    result = run_step(
        addressbook_name,
        addressbook_id,
        create_server_configuration,
        [addressbook_id, username, password, server_url],
    )
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"create_server_configuration failed with error: {result.message}",
        )

    result = run_step(
        addressbook_name,
        addressbook_id,
        create_addressbook_configuration,
        [addressbook_id, addressbook_url],
    )
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"create_addressbook_configuration failed with error: {result.message}",
        )

    result = run_step(addressbook_name, addressbook_id, create_local_configuration, [addressbook_id])
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"create_local_configuration failed with error: {result.message}",
        )

    result = run_step(
        addressbook_name,
        addressbook_id,
        create_two_way_configuration,
        [addressbook_name, addressbook_id],
    )
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"create_two_way_configuration failed with error: {result.message}",
        )

    result = run_step(addressbook_name, addressbook_id, run_first_sync, [addressbook_id])
    if not result.success:
        return SyncResponse(
            success=False,
            message=f"run_first_sync failed with error: {result.message}",
        )

    return SyncResponse(success=True, message=result.message)


def syncevolution_two_way_sync(addressbook_id: str) -> SyncResponse:
    try:
        response = two_way_sync(addressbook_id)
        if response.returncode != 0:
            return SyncResponse(
                success=False,
                message=f"syncevolution_two_way_sync failed with error: {response.stdout}",
            )
        return SyncResponse(success=True, message=response.stdout)
    except Exception as e:
        return SyncResponse(
            success=False,
            message=f"syncevolution_two_way_sync failed with error: {str(e)}",
        )
