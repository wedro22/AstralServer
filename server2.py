import os
from bottle import route, request, post, static_file, template, redirect, hook, response
import database2
import json

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

@route('/api/projects')
def get_projects():
    # Устанавливаем заголовок для JSON
    response.content_type = 'application/json'
    
    # Тестовые данные (временная заглушка)
    projects = [
        { "name": "Мой первый проект", "created": "2024-01-15" },
        { "name": "Тестовый проект", "created": "2024-01-20" },
        { "name": "Рабочий проект", "created": "2024-01-25" },
        { "name": "Проект номер четыре", "created": "2024-01-26" },
        { "name": "Пятый проект", "created": "2024-01-27" },
        { "name": "Шестой проект", "created": "2024-01-28" },
        { "name": "Седьмой проект", "created": "2024-01-29" },
        { "name": "Восьмой проект", "created": "2024-01-30" },
        { "name": "Девятый проект", "created": "2024-01-31" },
        { "name": "Десятый проект", "created": "2024-02-01" }
    ]
    
    return json.dumps({
        "success": True,
        "projects": projects
    })

