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

import json as json_
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Optional

from .mimetypes import guess_type


class Response:
    def __init__(self, url: str, success: bool, status_code: int, data: bytes):
        self.url = url
        self.success = success
        self.status_code = status_code
        self.data = data
        self.text = data.decode("utf-8", errors="ignore")

    def json(self) -> Dict:
        return json_.loads(self.data)

    def raise_for_status(self):
        if not self.success:
            raise ValueError(f"Request to url {self.url} failed with error: {self.text}")
        if self.status_code >= 300:
            raise ValueError(
                f"Request to url {self.url} failed with status code: {self.status_code} and error: {self.text}"
            )

    def __str__(self):
        return f"Response(url={self.url}, success={self.success}, status_code={self.status_code}, data={self.text})"

    def __repr__(self):
        return self.__str__()


def request(
    url: str,
    method: str,
    data: Optional[bytes] = None,
    headers: Optional[Dict[str, str]] = None,
    follow_redirects: bool = True,
    max_redirects: int = 10,
) -> Response:
    redirect_count = 0
    current_url = url
    current_method = method
    current_data = data

    while redirect_count < max_redirects:
        try:
            request = urllib.request.Request(
                current_url,
                data=current_data,
                headers=headers or {},
                method=current_method,
            )
            with urllib.request.urlopen(request) as response:
                return Response(
                    url=current_url,
                    success=True,
                    status_code=response.code,
                    data=response.read(),
                )
        except urllib.error.HTTPError as e:
            if follow_redirects and e.code in (301, 302, 303, 307, 308):
                redirect_count += 1
                location = e.headers.get("Location")
                if not location:
                    error_content = b""
                    try:
                        if e.fp:
                            error_content = e.fp.read()
                    except Exception:
                        pass
                    return Response(
                        url=current_url,
                        success=False,
                        status_code=e.code,
                        data=error_content,
                    )

                if not location.startswith(("http://", "https://")):
                    from urllib.parse import urljoin

                    location = urljoin(current_url, location)

                current_url = location

                if e.code == 303 or (e.code in (301, 302) and current_method in ("POST", "PUT", "DELETE")):
                    current_method = "GET"
                    current_data = None
                elif e.code in (307, 308):
                    pass

                continue
            else:
                error_content = b""
                try:
                    if e.fp:
                        error_content = e.fp.read()
                except Exception:
                    pass

                return Response(
                    url=current_url,
                    success=False,
                    status_code=e.code,
                    data=error_content,
                )
        except urllib.error.URLError as e:
            return Response(
                url=current_url,
                success=False,
                status_code=0,
                data=str(e.reason).encode(),
            )
        except Exception as e:
            return Response(url=current_url, success=False, status_code=0, data=str(e).encode())

    return Response(
        url=current_url,
        success=False,
        status_code=0,
        data=b"Maximum redirects exceeded",
    )


def post(url: str, json: Optional[Dict] = None, headers: Optional[Dict[str, str]] = None) -> Response:
    data = b""
    request_headers = {}
    if json:
        data = json_.dumps(json).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    if headers:
        request_headers.update(headers)

    return request(url, method="POST", data=data, headers=request_headers)


def get(
    url: str,
    headers: Optional[Dict[str, str]] = None,
    params: Optional[Dict[str, str]] = None,
) -> Response:
    request_headers = {}
    if params:
        query_string = urllib.parse.urlencode(params)
        url = f"{url}?{query_string}"

    if headers:
        request_headers.update(headers)

    return request(url, method="GET", headers=request_headers)


def put(url: str, json: Optional[Dict] = None, headers: Optional[Dict[str, str]] = None) -> Response:
    data = b""
    request_headers = {}
    if json:
        data = json_.dumps(json).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    if headers:
        request_headers.update(headers)

    return request(url, method="PUT", data=data, headers=request_headers)


def delete(url: str, json: Optional[Dict] = None, headers: Optional[Dict[str, str]] = None) -> Response:
    data = b""
    request_headers = {}
    if json:
        data = json_.dumps(json).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    if headers:
        request_headers.update(headers)

    return request(url, method="DELETE", data=data, headers=request_headers)


def post_file(
    url: str,
    file_data: bytes,
    file_name: str,
    file_field: str,
    form_fields: Optional[Dict[str, str]] = None,
    headers: Optional[Dict[str, str]] = None,
) -> Response:
    boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    content_type = f"multipart/form-data; boundary={boundary}"

    mime_type = guess_type(file_name)[0] or "application/octet-stream"

    body_parts = []

    if form_fields:
        for field_name, field_value in form_fields.items():
            body_parts.append(f"--{boundary}".encode())
            body_parts.append(f'Content-Disposition: form-data; name="{field_name}"'.encode())
            body_parts.append(b"")
            body_parts.append(str(field_value).encode())

    body_parts.append(f"--{boundary}".encode())
    body_parts.append(f'Content-Disposition: form-data; name="{file_field}"; filename="{file_name}"'.encode())
    body_parts.append(f"Content-Type: {mime_type}".encode())
    body_parts.append(b"")
    body_parts.append(file_data)

    body_parts.append(f"--{boundary}--".encode())

    body = b"\r\n".join(body_parts)

    request_headers = {"Content-Type": content_type}
    if headers:
        request_headers.update(headers)

    return request(url, method="POST", data=body, headers=request_headers)
