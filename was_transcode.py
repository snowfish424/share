from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.request

class TranscodeHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # 1. 抓取 WebSphere 原始資料 (以 latin-1 讀取避免直接崩潰)
            with urllib.request.urlopen("http://<您的WAS_IP>:9080/metrics") as response:
                raw_bytes = response.read()
            
            # 2. 將 Big5 轉碼為標準 UTF-8，解不掉的字元直接忽略
            clean_text = raw_bytes.decode('big5', errors='ignore')
            
            # 3. 回傳給請求者
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.end_headers()
            self.wfile.write(clean_text.encode('utf-8'))
        except Exception as e:
            self.send_error(500, str(e))

if __name__ == '__main__':
    HTTPServer(('127.0.0.1', 8999), TranscodeHandler).serve_forever()
