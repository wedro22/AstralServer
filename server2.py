import os
from bottle import route, request, post, static_file, template, redirect, hook, response
import database2

project_root = os.path.dirname(os.path.abspath(__file__))
database2.init_db()

@route('/favicon.ico')
def serve_favicon():
    try:
        response.content_type = 'image/x-icon'
        return serve_static('favicon.ico')
    except:
        # Если файл не найден, возвращаем пустой ответ
        response.status = 204
        return ''

@route('/static/<filename:path>')   # Статические файлы (CSS, JS) style.css
def serve_static(filename):
    return static_file(filename, root=project_root+'/static')

@route('/')
def hello():
    return '<a href="/astral">Перейти к Astral</a>'

@route('/astral', method=['GET', 'POST'])
def astral():
    if request.method == 'GET':
        return template('astral2')
    elif request.method == 'POST':
        # Заглушка для POST запроса
        return 'POST запрос получен'

