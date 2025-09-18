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

import base64
from dataclasses import dataclass
from typing import Dict, List, Optional
from urllib.parse import urljoin, urlparse
from xml.etree import ElementTree as ET

import src.ut_components.http as http


@dataclass
class AddressBook:
    name: str
    url: str


def format_basic_auth_header(username: str, password: str) -> str:
    credentials = f"{username}:{password}"
    encoded_credentials = base64.b64encode(credentials.encode("utf-8")).decode("utf-8")
    return f"Basic {encoded_credentials}"


def _discover_principal(base_url: str, username: str, password: str, namespaces: Dict) -> Optional[str]:
    propfind_body = """<?xml version="1.0" encoding="utf-8"?>
    <D:propfind xmlns:D="DAV:">
        <D:prop>
            <D:current-user-principal/>
        </D:prop>
    </D:propfind>"""

    response = http.request(
        method="PROPFIND",
        url=base_url,
        headers={
            "Depth": "0",
            "Content-Type": "application/xml; charset=utf-8",
            "Authorization": format_basic_auth_header(username, password),
        },
        data=propfind_body.encode(),
    )
    response.raise_for_status()

    if response.status_code in [207, 200]:
        root = ET.fromstring(response.text)

        # Look for current-user-principal href
        for elem in root.iter():
            if elem.tag.endswith("current-user-principal"):
                href_elem = elem.find(".//{DAV:}href")
                if href_elem is not None and href_elem.text:
                    return urljoin(base_url, href_elem.text)

    return None


def _discover_addressbook_home(principal_url: str, username: str, password: str, namespaces: Dict) -> Optional[str]:
    propfind_body = """<?xml version="1.0" encoding="utf-8"?>
    <D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav">
        <D:prop>
            <C:addressbook-home-set/>
        </D:prop>
    </D:propfind>"""

    response = http.request(
        method="PROPFIND",
        url=principal_url,
        headers={
            "Depth": "0",
            "Content-Type": "application/xml; charset=utf-8",
            "Authorization": format_basic_auth_header(username, password),
        },
        data=propfind_body.encode(),
    )
    response.raise_for_status()

    if response.status_code in [207, 200]:
        root = ET.fromstring(response.text)
        for elem in root.iter():
            if elem.tag.endswith("addressbook-home-set"):
                href_elem = elem.find(".//{DAV:}href")
                if href_elem is not None and href_elem.text:
                    return urljoin(principal_url, href_elem.text)

    return None


def _get_addressbooks_from_collection(
    collection_url: str, username: str, password: str, namespaces: Dict
) -> List[Dict[str, str]]:
    propfind_body = """<?xml version="1.0" encoding="utf-8"?>
    <D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav">
        <D:prop>
            <D:displayname/>
            <D:resourcetype/>
            <C:addressbook-description/>
        </D:prop>
    </D:propfind>"""

    addressbooks = []

    response = http.request(
        method="PROPFIND",
        url=collection_url,
        headers={
            "Depth": "1",
            "Content-Type": "application/xml; charset=utf-8",
            "Authorization": format_basic_auth_header(username, password),
        },
        data=propfind_body.encode(),
    )
    response.raise_for_status()

    if response.status_code in [207, 200]:
        root = ET.fromstring(response.text)

        for response_elem in root.findall(".//{DAV:}response"):
            href_elem = response_elem.find("{DAV:}href")
            if href_elem is None or not href_elem.text:
                continue

            is_addressbook = False
            for resourcetype in response_elem.iter("{DAV:}resourcetype"):
                if resourcetype.find(".//{urn:ietf:params:xml:ns:carddav}addressbook") is not None:
                    is_addressbook = True
                    break

            if is_addressbook:
                displayname = None
                displayname_elem = response_elem.find(".//{DAV:}displayname")
                if displayname_elem is not None and displayname_elem.text:
                    displayname = displayname_elem.text

                if not displayname:
                    desc_elem = response_elem.find(".//{urn:ietf:params:xml:ns:carddav}addressbook-description")
                    if desc_elem is not None and desc_elem.text:
                        displayname = desc_elem.text

                if not displayname:
                    path = urlparse(href_elem.text).path
                    displayname = path.rstrip("/").split("/")[-1] or "Address Book"

                addressbooks.append(
                    {
                        "name": displayname,
                        "url": urljoin(collection_url, href_elem.text),
                    }
                )

    return addressbooks


def get_carddav_addressbooks(server_url: str, username: str, password: str) -> List[AddressBook]:
    """
    Discover and retrieve CardDAV address books from a DAV server.

    Args:
        server_url: The base URL of the DAV server
        username: Username for authentication
        password: Password for authentication

    Returns:
        List of dictionaries containing address book information with 'name' and 'url' keys
    """

    if not server_url.endswith("/"):
        server_url += "/"

    namespaces = {
        "D": "DAV:",
        "C": "urn:ietf:params:xml:ns:carddav",
        "CS": "http://calendarserver.org/ns/",
        "CR": "urn:ietf:params:xml:ns:carddav",
    }

    addressbooks = []

    principal_url = _discover_principal(server_url, username, password, namespaces)
    if not principal_url:
        principal_url = server_url

    addressbook_home_url = _discover_addressbook_home(principal_url, username, password, namespaces)
    if not addressbook_home_url:
        addressbook_home_url = principal_url

    addressbooks = _get_addressbooks_from_collection(addressbook_home_url, username, password, namespaces)

    return [AddressBook(url=x.get("url", ""), name=x.get("name", "")) for x in addressbooks]
