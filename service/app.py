
import os
import json
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


def get_setting(name, default):
    config_path = f"/etc/app-config/{name}"

    try:
        with open(config_path, encoding="utf-8") as file:
            return file.read().strip()
    except FileNotFoundError:
        return os.getenv(name, default)


class AppHandler(BaseHTTPRequestHandler):

    def do_GET(self):

        if self.path == "/":
            response = {
                "app": get_setting("APP_NAME", "enterprise-bot"),
                "version": get_setting("VERSION", "1.0.0"),
                "pod": socket.gethostname()
            }

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

        elif self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(
                json.dumps({"status": "healthy"}).encode()
            )

        else:
            self.send_response(404)
            self.end_headers()


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))

    server = HTTPServer(("0.0.0.0", port), AppHandler)

    print(f"Application started on port {port}", flush=True)

    server.serve_forever()
