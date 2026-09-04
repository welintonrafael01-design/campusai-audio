#!/usr/bin/env python3
"""Serve QA artifacts without depending on reverse DNS resolution."""

from __future__ import annotations

import argparse
import os
import socketserver
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class QAHttpsServer(ThreadingHTTPServer):
    def server_bind(self) -> None:
        # http.server normally calls socket.getfqdn() here. That can block on
        # isolated QA machines even though the listening address is local.
        socketserver.TCPServer.server_bind(self)
        host, port = self.server_address[:2]
        self.server_name = str(host)
        self.server_port = int(port)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--bind", default="127.0.0.1")
    args = parser.parse_args()

    os.chdir(args.directory)
    with QAHttpsServer(
        (args.bind, args.port),
        SimpleHTTPRequestHandler,
    ) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
