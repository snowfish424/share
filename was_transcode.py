from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
import http.client
import sys
from urllib.parse import urlparse, parse_qs

class TranscodeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        parsed_url = urlparse(self.path)
        query_params = parse_qs(parsed_url.query)
        
        if 'metrics' in parsed_url.path and 'target' in query_params:
            was_target = query_params['target'][0] # 取得如 192.168.1.11:9080
            
            # 拆分 IP 與 Port
            if ":" in was_target:
                host, port = was_target.split(":", 1)
                port = int(port)
            else:
                host = was_target
                port = 80
            
            conn = None
            try:
                # 使用底層 http.client 建立連線，設定 3 秒超時
                conn = http.client.HTTPConnection(host, port, timeout=3)
                conn.request("GET", "/metrics")
                response = conn.getresponse()
                
                raw_bytes = response.read()
                
                # 轉碼並忽略損毀字元
                clean_text = raw_bytes.decode('big5', errors='ignore')
                
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
                self.end_headers()
                self.wfile.write(clean_text.encode('utf-8'))
                
            except Exception as e:
                self.send_response(500)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"# ERROR: {was_target} failed: {str(e)}\n".encode('utf-8'))
            finally:
                if conn:
                    conn.close() # 嚴格確保連線關閉，釋放 Socket 資源
        else:
            self.send_error(400, "Bad Request")

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    allow_reuse_address = True

if __name__ == '__main__':
    try:
        server = ThreadedHTTPServer(('127.0.0.1', 8999), TranscodeHandler)
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
