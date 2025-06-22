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

@route('/api/projects', method='GET')
def get_projects():
    """Список всех проектов."""
    response.content_type = 'application/json'
    projects = database2.list_projects()
    return json.dumps({
        "success": True,
        "projects": projects,
    }, ensure_ascii=False)

@post('/api/projects')
def create_project():
    """Создание нового проекта."""
    response.content_type = 'application/json'
    data = request.json or {}
    name = data.get('name')
    if not name:
        response.status = 400
        return json.dumps({"success": False, "message": "Поле 'name' обязательно"}, ensure_ascii=False)

    try:
        project = database2.add_project(name)
    except Exception as e:
        response.status = 400
        return json.dumps({"success": False, "message": str(e)}, ensure_ascii=False)

    response.status = 201
    return json.dumps({"success": True, "project": project}, ensure_ascii=False)

