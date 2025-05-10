# Python HTTP Server

## It's Easy

### http.server

#### http ne-liner

To start a simple HTTP server in Python, use the following one-liner command in your terminal or command prompt:

```python
python -m http.server 8000
```

#### Serving a Directory

To serve files from a specific directory, navigate to that directory in your terminal or command prompt and run the server command. For example, if you want to serve files from a directory named myproject, navigate to myproject and run:

```python
python -m http.server 8000
```

#### Choosing a Port

By default, the server runs on port 8000. If you want to use a different port, specify it as an argument after the server command. For example, to run the server on port 9000:

```python
python -m http.server 9000
```

### Serviing Files Over a Network

`webserver.py`

```python
import http.server
import socketserver

PORT = 8000

Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print("serving at port", PORT)
    httpd.serve_forever()
```

To run the file:

`python webserver.py`

It will serve the directory it is started in. If you add an `index.html` to the directory, it will automatically serve that.

## Resources

- [Digital Ocean python http server](https://www.digitalocean.com/community/tutorials/python-simplehttpserver-http-server)

- [Digital Ocean Python Turtorial](https://www.digitalocean.com/community/tutorials/python-tutorial-beginners)