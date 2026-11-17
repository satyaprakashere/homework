import http.server
import socketserver
import json
import sqlite3
import os

PORT = 8081
DB_FILE = "editor.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS document (id INTEGER PRIMARY KEY, content TEXT)''')
    c.execute("SELECT COUNT(*) FROM document")
    if c.fetchone()[0] == 0:
        c.execute("INSERT INTO document (content) VALUES ('')")
    conn.commit()
    conn.close()

class Handler(http.server.BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path == "/api/document":
            conn = sqlite3.connect(DB_FILE)
            c = conn.cursor()
            c.execute("SELECT content FROM document WHERE id = 1")
            content = c.fetchone()[0]
            conn.close()

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"content": content}).encode())
        else:
            # Serve static files
            path = self.path
            if path == "/":
                path = "/index.html"
            
            # Map path to project root (one level up from backend/)
            file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", path.lstrip("/")))
            
            if os.path.exists(file_path) and os.path.isfile(file_path):
                self.send_response(200)
                if file_path.endswith(".html"):
                    self.send_header("Content-Type", "text/html")
                elif file_path.endswith(".css"):
                    self.send_header("Content-Type", "text/css")
                elif file_path.endswith(".js"):
                    self.send_header("Content-Type", "application/javascript")
                self.end_headers()
                with open(file_path, "rb") as f:
                    self.wfile.write(f.read())
            else:
                self.send_response(404)
                self.end_headers()

    def do_POST(self):
        if self.path == "/api/document":
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)

            conn = sqlite3.connect(DB_FILE)
            c = conn.cursor()
            c.execute("UPDATE document SET content = ? WHERE id = 1", (data['content'],))
            conn.commit()
            conn.close()

            self.send_response(200)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    init_db()
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Server started at http://localhost:{PORT}")
        httpd.serve_forever()
