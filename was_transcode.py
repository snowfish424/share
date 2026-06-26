from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.request
import sys
from urllib.parse import urlparse, parse_qs

class TranscodeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        # 解析網址與參數
        parsed_url = urlparse(self.path)
        query_params = parse_qs(parsed_url.query)
        
        # 只要路徑包含 metrics 且有帶 target 參數就處理
        if 'metrics' in parsed_url.path and 'target' in query_params:
            was_target = query_params['target'][0] # 取得如 192.168.1.11:9080
            
            try:
                # 動態組出目標 WAS 的 metrics 網址
                was_url = f"http://{was_target}/metrics"
                
                # 抓取該台 WebSphere 原始資料
                with urllib.request.urlopen(was_url, timeout=5) as response:
                    raw_bytes = response.read()
                
                # 轉碼為標準 UTF-8
                clean_text = raw_bytes.decode('big5', errors='ignore')
                
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
                self.end_headers()
                self.wfile.write(clean_text.encode('utf-8'))
            except Exception as e:
                self.send_error(500, f"Error fetching from {was_target}: {str(e)}")
        else:
            self.send_error(400, "Bad Request: Missing target parameter")

if __name__ == '__main__':
    try:
        server = HTTPServer(('127.0.0.1', 8999), TranscodeHandler)
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)
