from http.server import HTTPServer, BaseHTTPRequestHandler
from cgi import FieldStorage,parse_header
from io import BytesIO
import cgi
import socket

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def writeBinaryData(data):
       
        global image_no

        filename = "image_" + str(image_no) + ".png"
        print("Writing to file ...")
        file = open(filename,"wb")
        file.write(data)
        file.close()

        image_no = image_no + 1

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Hello, world!')

    def do_POST(self):
        ctype, pdict = cgi.parse_header(self.headers.getheader('content-type'))
        if ctype == 'multipart/form-data':
                postvars = cgi.parse_multipart(self.rfile, pdict)
        elif ctype == 'application/x-www-form-urlencoded':
                length = int(self.headers.getheader('content-length'))
                postvars = cgi.parse_qs(self.rfile.read(length), keep_blank_values=1)
        else:
                postvars = {}

        writeBinaryData(postvars['image_file'][0])
        self.send_response(200)
        self.end_headers()
        response = BytesIO()
        response.write(b'Image saved')
        self.wfile.write(response.getvalue())

'''
Example: curl -F "image_file=@/Users/egi/Downloads/Contexto.png " -X POST http://localhost:8000
'''
image_no = 0
my_ip_address = get_ip()
print("Starting server in " + my_ip_address)
httpd = HTTPServer((my_ip_address, 8000), SimpleHTTPRequestHandler)
httpd.serve_forever()

