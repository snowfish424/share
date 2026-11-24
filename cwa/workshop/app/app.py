"""Workshop-only HTTP API. All weather values are synthetic demonstration data."""
import json
import os
import signal
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


def main():
    data_dir = Path(os.getenv("DATA_DIR", "/opt/app/data"))
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "startup.txt").write_text(
        datetime.now(timezone.utc).isoformat(), encoding="utf-8"
    )

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            status = 200
            if path == "/healthz":
                payload = {"status": "alive"}
            elif path == "/readyz":
                ready = os.getenv("READY", "true").lower() == "true"
                status = 200 if ready else 503
                payload = {"ready": ready}
            elif path in ("/", "/observations"):
                payload = {
                    "application": "cwa-weather-demo",
                    "version": os.getenv("APP_VERSION", "dev"),
                    "message": os.getenv("APP_MESSAGE", "Podman to OpenShift"),
                    "station": os.getenv("STATION_NAME", "Taipei-DEMO"),
                    "temperature_c": 26.5,
                    "sample_data": True,
                    "pod": socket.gethostname(),
                    "uid": os.getuid(),
                    "data_dir_writable": os.access(data_dir, os.W_OK),
                }
            else:
                status, payload = 404, {"error": "not found"}
            body = (json.dumps(payload, ensure_ascii=False) + "\n").encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    def terminate(_signum, _frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, terminate)
    server = ThreadingHTTPServer(("0.0.0.0", int(os.getenv("PORT", "8080"))), Handler)
    print(json.dumps({"event": "started", "uid": os.getuid(), "port": server.server_port}), flush=True)
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
