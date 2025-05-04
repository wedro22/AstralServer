# server.py
from bottle import route, run, request, post, get, default_app
from database import init_db, get_all_clients, add_client
from astral_page import setup_astral_routes

init_db()

@post('/add_client')
def add_client_route():
    client_name = request.forms.get('client_name')
    if client_name:
        add_client(client_name)
        return {"status": "success", "client": client_name}
    return {"status": "error", "message": "No client name provided"}

@route('/')
def hello():
    return "Пыщ!"

@post('/echo')
def echo():
    return 'You sent: ' + request.body.read().decode('utf-8')

@get('/astral/data')
def getAstral():
    return "Data not implemented yet"

@post('/astral/data')
def postAstral():
    return {"status": "OK"}

app = default_app()
setup_astral_routes(app)
run(host='127.0.0.1', port=8000)