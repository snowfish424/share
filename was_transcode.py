from http.server import BaseHTTPRequestHandler, HTTPServer
import socketserver
import urllib.request
import sys
from urllib.parse import urlparse, parse_qs

class TranscodeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        parsed_url = urlparse(self.path)
        query_params = parse_qs(parsed_url.query)
        
        if 'metrics' in parsed_url.path and 'target' in query_params:
            was_target = query_params['target'][0] # 取得目標 IP:PORT
            
            try:
                was_url = f"http://{was_target}/metrics"
                
                # 設定 4 秒超時，避免某台 WAS 掛掉時無限期佔用執行緒
                with urllib.request.urlopen(was_url, timeout=4) as response:
                    raw_bytes = response.read()
                
                clean_text = raw_bytes.decode('big5', errors='ignore')
                
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
                self.end_headers()
                self.wfile.write(clean_text.encode('utf-8'))
            except Exception as e:
                # 某一台 WAS 失敗時，僅回傳該台錯誤，不影響其他執行緒
                self.send_response(500)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"# ERROR: Cannot fetch from {was_target}: {str(e)}\n".encode('utf-8'))
        else:
            self.send_error(400, "Bad Request")

# 關鍵核心：透過 ThreadingMixIn 建立支援多執行緒的 HTTP 伺服器
class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    # 允許連接埠快速重用，避免重啟服務時噴出 Address already in use
    allow_reuse_address = True 

if __name__ == '__main__':
    try:
        # 使用新的 ThreadedHTTPServer 啟動
        server = ThreadedHTTPServer(('127.0.0.1', 8999), TranscodeHandler)
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
