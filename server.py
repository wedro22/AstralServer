from bottle import route, run, request, post, get


@route('/')
def hello():
    return "Hello, World!"

@route('/test')
def test():
    return "Пыщ!"

@post('/echo')
def echo():
    return 'You sent: ' + request.body.read().decode('utf-8')

@route('/astral', method=['GET', 'POST'])
def echo():
    #return 'You sent: ' + request.body.read().decode('utf-8')
    return "Пыщ!"

run(host='127.0.0.1', port=8000)