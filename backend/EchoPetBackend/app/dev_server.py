from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

from .agent import build_companion_reply
from .settings import settings


class EchoPetDevHandler(BaseHTTPRequestHandler):
    server_version = "EchoPetDevServer/0.1"

    def do_GET(self) -> None:
        if self.path == "/health":
            self._send_json(
                {
                    "status": "ok",
                    "environment": settings.environment,
                    "aiProvider": settings.ai_provider,
                    "aiModel": settings.ai_model,
                    "aiMode": settings.ai_mode,
                    "server": "stdlib-preview",
                }
            )
            return

        self._send_json({"error": "not_found"}, status=404)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        segments = [segment for segment in parsed.path.split("/") if segment]

        if (
            len(segments) == 5
            and segments[0] == "v1"
            and segments[1] == "pets"
            and segments[3] == "companion"
            and segments[4] == "chat"
        ):
            pet_id = segments[2]
            request = self._read_json()
            self._send_json(build_companion_reply(request, pet_id=pet_id))
            return

        self._send_json({"error": "not_found"}, status=404)

    def log_message(self, format: str, *args: object) -> None:
        return

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}

        body = self.rfile.read(length)
        return json.loads(body.decode("utf-8"))

    def _send_json(self, payload: dict, status: int = 200) -> None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def run(host: str = "127.0.0.1", port: int = 8000) -> None:
    server = ThreadingHTTPServer((host, port), EchoPetDevHandler)
    print(f"Echo Pet backend preview server running at http://{host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    run()
