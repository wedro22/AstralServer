from bottle import route, run, request, post, get
import sqlite3

# Инициализация БД
def init_db():
    conn = sqlite3.connect('astral.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS CommandList (
                id INTEGER PRIMARY KEY,
                client TEXT,
                data TEXT,
                type TEXT   
                )''') #TEXT NOT NULL если надо
    conn.commit()
    c.execute('CREATE INDEX idx_client ON CommandList (client)')
    conn.commit()
    conn.close()

init_db()

@route('/')
def hello():
    return "Пыщ!"

@post('/echo')
def echo():
    return 'You sent: ' + request.body.read().decode('utf-8')

@route('/astral')
def astral():
    return

@get('/astral/data')
def getAstral():
    #key = request.query.key  # GET-параметр
    #return storage.get(key)
    return

@post('/astral/data')
def postAstral():
    #data = request.json  # JSON-тело
    #storage[data['key']] = data['value']
    #return {"status": "OK"}
    return

run(host='127.0.0.1', port=8000)