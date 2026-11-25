"""Actual Swift client + FastAPI: lose acknowledgments, restart both, retry once."""
import http.client
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time


def stop(process):
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=10)


def main():
    root = Path(__file__).resolve().parents[2]
    binary = Path(sys.argv[1]).resolve()
    with tempfile.TemporaryDirectory() as directory, socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        listener.listen()
        backend_port = listener.getsockname()[1]
        environment = {**os.environ, 'SPEECH_SESSION_DB': str(Path(directory) / 'sessions.sqlite3')}

        class Proxy(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def forward(self):
                body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
                connection = http.client.HTTPConnection('127.0.0.1', backend_port, timeout=10)
                try:
                    connection.request(self.command, self.path, body=body,
                                       headers={'Content-Type': 'application/json'})
                    response = connection.getresponse()
                    payload = response.read()
                    status = response.status
                finally:
                    connection.close()
                if self.command == 'POST' and self.server.drop_responses:
                    if status != 200:
                        self.server.failure = f'Backend rejected the fixture: {status}'
                    self.close_connection = True
                    try:
                        self.connection.shutdown(socket.SHUT_RDWR)
                    except OSError:
                        pass
                    return
                self.send_response(status)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)

            do_GET = forward
            do_POST = forward

        proxy = ThreadingHTTPServer(('127.0.0.1', 0), Proxy)
        proxy.drop_responses = True
        proxy.failure = None
        thread = threading.Thread(target=proxy.serve_forever, daemon=True)
        thread.start()
        try:
            for phase in ('lost-response', 'restart'):
                proxy.drop_responses = phase == 'lost-response'
                with tempfile.TemporaryFile() as log:
                    process = subprocess.Popen(
                        [sys.executable, '-m', 'uvicorn', 'main:app', '--fd', str(listener.fileno())],
                        cwd=root / 'backend', env=environment, pass_fds=(listener.fileno(),),
                        stdout=log, stderr=log,
                    )
                    try:
                        deadline = time.monotonic() + 30
                        while True:
                            connection = http.client.HTTPConnection('127.0.0.1', backend_port, timeout=1)
                            try:
                                connection.request('GET', '/health')
                                response = connection.getresponse()
                                response.read()
                                if response.status == 200:
                                    break
                            except (OSError, http.client.HTTPException):
                                pass
                            finally:
                                connection.close()
                            if process.poll() is not None or time.monotonic() >= deadline:
                                log.seek(0)
                                raise RuntimeError(log.read().decode(errors='replace'))
                            time.sleep(.05)
                        subprocess.run([
                            str(binary), f'http://127.0.0.1:{proxy.server_port}/api',
                            str(Path(directory) / 'outbox.json'), phase,
                        ], check=True, timeout=90)
                        if proxy.failure:
                            raise RuntimeError(proxy.failure)
                    finally:
                        stop(process)
        finally:
            proxy.shutdown()
            proxy.server_close()
            thread.join(timeout=5)
    print('Actual Swift/FastAPI acknowledgment-loss, both-process restart and duplicate-safe progress passed')


if __name__ == '__main__':
    main()
