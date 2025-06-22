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
    
    try:
        # Получаем реальные проекты из базы данных
        projects = database2.get_all_projects()
        
        return json.dumps({
            "success": True,
            "projects": projects
        })
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": str(e)
        })

@route('/api/projects', method='POST')
def create_project():
    response.content_type = 'application/json'
    
    try:
        data = request.json
        project_name = data.get('name', '').strip()
        
        if not project_name:
            return json.dumps({"success": False, "error": "Имя проекта не может быть пустым"})
        
        database2.create_project(project_name)
        return json.dumps({"success": True})
        
    except Exception as e:
        return json.dumps({"success": False, "error": str(e)})

