"""Launch ARTEMIS pytest with placeholder credentials and no external sockets."""

import ipaddress
import os
import socket
import sys

import pytest


def main():
    for name in ("GOOGLE_API_KEY", "GEMINI_API_KEY", "OPENAI_API_KEY"):
        os.environ[name] = "offline-placeholder-no-credential"
    for name in tuple(os.environ):
        if name.upper().endswith("_PROXY") or name in (
            "ARTEMIS_DEEPSEEK_LEDGER_FILE", "ARTEMIS_DEEPSEEK_ONLY", "ARTEMIS_FAKE_LLM",
            "ARTEMIS_DEEPSEEK_REQUEST_LIMIT", "ARTEMIS_DEEPSEEK_COUNTER_FILE", "DEEPSEEK_API_KEY",
            "GOOGLE_APPLICATION_CREDENTIALS", "GOOGLE_GENAI_USE_VERTEXAI",
        ):
            os.environ.pop(name, None)

    def local(host):
        if host in (None, "localhost"):
            return True
        try:
            return ipaddress.ip_address(host).is_loopback
        except ValueError:
            return False

    original_dns = socket.getaddrinfo

    def offline_dns(host, *args, **kwargs):
        if not local(host):
            raise AssertionError("Offline suite tried external DNS")
        return original_dns(host, *args, **kwargs)

    def offline_socket(original):
        def connect(sock, address):
            if isinstance(address, tuple) and not local(address[0]):
                raise AssertionError("Offline suite tried external socket")
            return original(sock, address)
        return connect

    socket.getaddrinfo = offline_dns
    socket.socket.connect = offline_socket(socket.socket.connect)
    socket.socket.connect_ex = offline_socket(socket.socket.connect_ex)
    return pytest.main(sys.argv[1:])


if __name__ == "__main__":
    sys.exit(main())
