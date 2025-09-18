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

import json as json_
import urllib.error
import urllib.parse
import urllib.request
from typing import Dict, Optional

from .mimetypes import guess_type


class Response:
    """
    HTTP Response wrapper for handling API responses in Ubuntu Touch applications.

    This class provides a convenient interface for working with HTTP responses,
    including automatic text decoding, JSON parsing, and status validation.
    It encapsulates the response data and provides utility methods for common
    operations like checking for errors or parsing JSON content.

    Attributes:
        url (str): The URL that was requested.
        success (bool): Whether the request completed without network errors.
        status_code (int): HTTP status code (200, 404, etc.). 0 for network errors.
        data (bytes): Raw response body as bytes.
        text (str): Response body decoded as UTF-8 string.

    Example:
        >>> from src.ut_components.http import get
        >>>
        >>> response = get("https://api.example.com/data")
        >>> if response.success:
        ...     print(f"Status: {response.status_code}")
        ...     print(f"Data: {response.text}")
        >>> else:
        ...     print(f"Request failed: {response.text}")
    """

    def __init__(self, url: str, success: bool, status_code: int, data: bytes):
        self.url = url
        self.success = success
        self.status_code = status_code
        self.data = data
        self.text = data.decode("utf-8", errors="ignore")

    def json(self) -> Dict:
        """
        Parse the response body as JSON.

        Converts the response data from bytes to a Python dictionary or list
        by parsing it as JSON. This is useful for working with REST APIs that
        return JSON responses.

        Returns:
            Dict: Parsed JSON data as a Python dictionary or list.

        Raises:
            json.JSONDecodeError: If the response body is not valid JSON.

        Example:
            >>> response = get("https://api.example.com/user/123")
            >>> if response.success:
            ...     user_data = response.json()
            ...     print(f"User name: {user_data['name']}")
        """
        return json_.loads(self.data)

    def raise_for_status(self):
        """
        Raise an exception if the request failed or returned an error status.

        This method checks both the success flag (network-level success) and
        the HTTP status code. It raises an exception if either indicates a failure.
        Use this for fail-fast error handling when you expect successful responses.

        Raises:
            ValueError: If success is False (network error) or status_code >= 300.

        Example:
            >>> response = post("https://api.example.com/data", json={"key": "value"})
            >>> try:
            ...     response.raise_for_status()
            ...     data = response.json()
            ... except ValueError as e:
            ...     print(f"Request failed: {e}")
        """
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
    """
    Perform a generic HTTP request with automatic redirect handling.

    This is the core function that handles all HTTP methods. It provides full
    control over the request, including custom methods, headers, and redirect
    behavior. It automatically handles various redirect status codes and follows
    them according to HTTP specifications.

    Args:
        url (str): The target URL for the request.
        method (str): HTTP method (GET, POST, PUT, DELETE, PATCH, etc.).
        data (Optional[bytes]): Request body as bytes. Defaults to None.
        headers (Optional[Dict[str, str]]): HTTP headers to include in the request.
            Defaults to empty dict.
        follow_redirects (bool): Whether to automatically follow HTTP redirects.
            Defaults to True.
        max_redirects (int): Maximum number of redirects to follow before failing.
            Defaults to 10.

    Returns:
        Response: A Response object containing the result of the HTTP request.

    Example:
        >>> from src.ut_components.http import request
        >>>
        >>> # Custom PATCH request
        >>> response = request(
        ...     url="https://api.example.com/resource/123",
        ...     method="PATCH",
        ...     data=b'{"status": "updated"}',
        ...     headers={"Content-Type": "application/json"}
        ... )
        >>>
        >>> # HEAD request without following redirects
        >>> response = request(
        ...     url="https://example.com/page",
        ...     method="HEAD",
        ...     follow_redirects=False
        ... )
    """
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
    """
    Perform an HTTP POST request to send data to a server.

    POST requests are used to submit data to be processed to a specified resource.
    This function automatically handles JSON serialization and sets the appropriate
    Content-Type header when JSON data is provided. It's commonly used for creating
    new resources or submitting form data to APIs.

    Args:
        url (str): The target URL for the POST request.
        json (Optional[Dict]): Python dictionary to be sent as JSON in the request body.
            Will be automatically serialized and Content-Type will be set to
            application/json. Defaults to None.
        headers (Optional[Dict[str, str]]): Additional HTTP headers to include.
            The Content-Type header is automatically set when json is provided.
            Defaults to None.

    Returns:
        Response: A Response object containing the server's response.

    Example:
        >>> from src.ut_components.http import post
        >>>
        >>> # Create a new user
        >>> response = post(
        ...     url="https://api.example.com/users",
        ...     json={
        ...         "name": "John Doe",
        ...         "email": "john@example.com"
        ...     }
        ... )
        >>> if response.success:
        ...     created_user = response.json()
        ...     print(f"User created with ID: {created_user['id']}")
        >>>
        >>> # POST with custom headers
        >>> response = post(
        ...     url="https://api.example.com/messages",
        ...     json={"text": "Hello Ubuntu Touch!"},
        ...     headers={"Authorization": "Bearer token123"}
        ... )
    """
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
    """
    Perform an HTTP GET request to retrieve data from a server.

    GET requests are used to retrieve data from a specified resource. This function
    simplifies making GET requests by handling query parameter encoding and providing
    a clean interface for adding custom headers. Query parameters are automatically
    URL-encoded and appended to the URL.

    Args:
        url (str): The target URL for the GET request.
        headers (Optional[Dict[str, str]]): HTTP headers to include in the request.
            Common headers include Authorization, User-Agent, etc. Defaults to None.
        params (Optional[Dict[str, str]]): Query parameters to append to the URL.
            These will be URL-encoded automatically. Defaults to None.

    Returns:
        Response: A Response object containing the server's response.

    Example:
        >>> from src.ut_components.http import get
        >>>
        >>> # Simple GET request
        >>> response = get("https://api.example.com/users")
        >>> if response.success:
        ...     users = response.json()
        >>>
        >>> # GET with query parameters
        >>> response = get(
        ...     url="https://api.example.com/search",
        ...     params={"q": "ubuntu touch", "limit": "10"}
        ... )
        >>>
        >>> # GET with authentication header
        >>> response = get(
        ...     url="https://api.example.com/profile",
        ...     headers={"Authorization": "Bearer token123"}
        ... )
    """
    request_headers = {}
    if params:
        query_string = urllib.parse.urlencode(params)
        url = f"{url}?{query_string}"

    if headers:
        request_headers.update(headers)

    return request(url, method="GET", headers=request_headers)


def put(url: str, json: Optional[Dict] = None, headers: Optional[Dict[str, str]] = None) -> Response:
    """
    Perform an HTTP PUT request to update existing resources on a server.

    PUT requests are used to update or replace an existing resource at a specified URL.
    This function automatically handles JSON serialization and sets the appropriate
    Content-Type header when JSON data is provided. It's commonly used for updating
    entire resources in RESTful APIs.

    Args:
        url (str): The target URL for the PUT request, typically including the
            resource identifier.
        json (Optional[Dict]): Python dictionary to be sent as JSON in the request body.
            Will be automatically serialized and Content-Type will be set to
            application/json. Defaults to None.
        headers (Optional[Dict[str, str]]): Additional HTTP headers to include.
            The Content-Type header is automatically set when json is provided.
            Defaults to None.

    Returns:
        Response: A Response object containing the server's response.

    Example:
        >>> from src.ut_components.http import put
        >>>
        >>> # Update an existing user
        >>> response = put(
        ...     url="https://api.example.com/users/123",
        ...     json={
        ...         "name": "Jane Doe",
        ...         "email": "jane.doe@example.com",
        ...         "status": "active"
        ...     }
        ... )
        >>> if response.success:
        ...     updated_user = response.json()
        ...     print(f"User updated: {updated_user['name']}")
        >>>
        >>> # PUT with authorization
        >>> response = put(
        ...     url="https://api.example.com/settings/theme",
        ...     json={"theme": "dark", "font_size": "large"},
        ...     headers={"Authorization": "Bearer token123"}
        ... )
    """
    data = b""
    request_headers = {}
    if json:
        data = json_.dumps(json).encode("utf-8")
        request_headers["Content-Type"] = "application/json"

    if headers:
        request_headers.update(headers)

    return request(url, method="PUT", data=data, headers=request_headers)


def delete(url: str, json: Optional[Dict] = None, headers: Optional[Dict[str, str]] = None) -> Response:
    """
    Perform an HTTP DELETE request to remove a resource from a server.

    DELETE requests are used to delete a specified resource. While DELETE requests
    typically don't have a body, this function supports sending JSON data for APIs
    that require additional information for deletion (like reasons or options).
    This is commonly used for removing resources in RESTful APIs.

    Args:
        url (str): The target URL for the DELETE request, typically including
            the resource identifier.
        json (Optional[Dict]): Optional JSON data to send in the request body.
            Some APIs require deletion reasons or options. Will be automatically
            serialized. Defaults to None.
        headers (Optional[Dict[str, str]]): Additional HTTP headers to include.
            The Content-Type header is automatically set when json is provided.
            Defaults to None.

    Returns:
        Response: A Response object containing the server's response.

    Example:
        >>> from src.ut_components.http import delete
        >>>
        >>> # Delete a user
        >>> response = delete("https://api.example.com/users/123")
        >>> if response.success:
        ...     print("User deleted successfully")
        >>>
        >>> # Delete with reason/options
        >>> response = delete(
        ...     url="https://api.example.com/posts/456",
        ...     json={"reason": "Spam content", "notify_author": True}
        ... )
        >>>
        >>> # Delete with authorization
        >>> response = delete(
        ...     url="https://api.example.com/sessions/current",
        ...     headers={"Authorization": "Bearer token123"}
        ... )
    """
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
    """
    Upload a file to a server using multipart/form-data encoding.

    This function handles file uploads by creating a proper multipart/form-data
    request. It automatically detects the file's MIME type based on the filename
    and can include additional form fields alongside the file. This is commonly
    used for uploading images, documents, or other files to web services.

    Args:
        url (str): The target URL for the file upload.
        file_data (bytes): The file content as bytes. You need to read the file
            into memory before passing it to this function.
        file_name (str): The name of the file being uploaded. Used for MIME type
            detection and sent to the server as the filename.
        file_field (str): The form field name for the file. This is the parameter
            name the server expects for the file upload.
        form_fields (Optional[Dict[str, str]]): Additional form fields to include
            with the file upload. These are sent as regular form data. Defaults to None.
        headers (Optional[Dict[str, str]]): Additional HTTP headers to include.
            The Content-Type header is automatically set with the boundary. Defaults to None.

    Returns:
        Response: A Response object containing the server's response.

    Example:
        >>> from src.ut_components.http import post_file
        >>>
        >>> # Upload a profile picture
        >>> with open("avatar.png", "rb") as f:
        ...     file_content = f.read()
        >>>
        >>> response = post_file(
        ...     url="https://api.example.com/upload",
        ...     file_data=file_content,
        ...     file_name="avatar.png",
        ...     file_field="profile_pic"
        ... )
        >>> if response.success:
        ...     result = response.json()
        ...     print(f"File uploaded: {result['url']}")
        >>>
        >>> # Upload with additional form fields
        >>> response = post_file(
        ...     url="https://api.example.com/documents",
        ...     file_data=document_bytes,
        ...     file_name="report.pdf",
        ...     file_field="document",
        ...     form_fields={
        ...         "title": "Q4 Report",
        ...         "category": "financial",
        ...         "public": "false"
        ...     },
        ...     headers={"Authorization": "Bearer token123"}
        ... )
    """
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
