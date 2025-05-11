# server.py
from bottle import route, run, request, post, static_file, template, redirect, hook
import database

@route('/')
def hello():
    return "Пыщ!"

@post('/echo')
def echo():
    return 'You sent: ' + request.body.read().decode('utf-8')

@route('/static/<filename:path>')   # Статические файлы (CSS, JS) style.css
def serve_static(filename):
    return static_file(filename, root='./static')


@hook('before_request')
def strip_trailing_slash():
    """Удаляет слеши в конце URL перед обработкой запроса"""
    original_path = request.path
    # Исключаем специальные роуты (например, /raw/)
    if not original_path.endswith('/raw/') and original_path != '/':
        while original_path.endswith('/'):
            original_path = original_path[:-1]

        if original_path != request.path:
            redirect(original_path)


@route('/astral', method=['GET', 'POST'])
def astral():
    if request.method == 'POST':
        client_name = request.forms.getunicode('client_name', '').strip()   # Используем getunicode вместо get

        if not client_name:
            return template('astral', error="Имя клиента не может быть пустым")

        result = database.astral_client_creation(client_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}")
        else:
            return template('astral', error=result['message'])

    return template('astral')


# Удаление клиента
@route('/astral/<client_name>/action/delete', method=['POST'])
def delete_client_route(client_name):
    result = database.delete_client(client_name)
    if result['status'] == 'success':
        return redirect("/astral")
    return template('astral', error=result.get('message'))

# Удаление проекта
@route('/astral/<client_name>/<project_name>/action/delete', method=['POST'])
def delete_project_route(client_name, project_name):
    result = database.delete_project(client_name, project_name)
    if result['status'] == 'success':
        return redirect(f"/astral/{client_name}")
    projects = database.get_client_projects(client_name)
    return template('client', client_name=client_name,
                   projects=projects, error=result.get('message'))

# Удаление скрипта
@route('/astral/<client_name>/<project_name>/<script_name>/action/delete', method=['POST'])
def delete_script_route(client_name, project_name, script_name):
    result = database.delete_script(client_name, project_name, script_name)
    if result['status'] == 'success':
        return redirect(f"/astral/{client_name}/{project_name}")
    scripts = database.get_project_scripts(client_name, project_name)
    return template('project', client_name=client_name,
                   project_name=project_name, scripts=scripts,
                   error=result.get('message'))


@route('/astral/<client_name>', method=['GET', 'POST'])
def client_page(client_name):
    if request.method == 'POST':
        project_name = request.forms.getunicode('project_name', '').strip()

        if not project_name:
            projects = database.get_client_projects(client_name)
            return template('client',
                            client_name=client_name,
                            projects=projects,
                            error="Имя проекта не может быть пустым")

        result = database.astral_project_creation(client_name, project_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}/{project_name}")
        else:
            projects = database.get_client_projects(client_name)
            return template('client',
                            client_name=client_name,
                            projects=projects,
                            error=result['message'])

    projects = database.get_client_projects(client_name)
    if projects is None:
        return "Клиент не найден"

    return template('client',
                    client_name=client_name,
                    projects=projects,
                    error=None)


@route('/astral/<client_name>/<project_name>', method=['GET', 'POST'])
def project_page(client_name, project_name):
    if request.method == 'POST':
        script_name = request.forms.getunicode('script_name', '').strip()

        if not script_name:
            scripts = database.get_project_scripts(client_name, project_name)
            return template('project',
                            client_name=client_name,
                            project_name=project_name,
                            scripts=scripts,
                            error="Имя скрипта не может быть пустым")

        result = database.astral_script_creation(client_name, project_name, script_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}/{project_name}/{script_name}")
        else:
            scripts = database.get_project_scripts(client_name, project_name)
            return template('project',
                            client_name=client_name,
                            project_name=project_name,
                            scripts=scripts,
                            error=result['message'])

    scripts = database.get_project_scripts(client_name, project_name)
    if scripts is None:
        return "Проект не найден"

    return template('project',
                    client_name=client_name,
                    project_name=project_name,
                    scripts=scripts,
                    error=None)


@route('/astral/<client_name>/<project_name>/<script_name>', method=['GET', 'POST'])
def script_page(client_name, project_name, script_name):
    if request.method == 'POST':
        if 'save' in request.forms:
            script_data = request.forms.getunicode('script_data', '')
            result = database.save_script_data(client_name, project_name, script_name, script_data)
            #latest_script_data = script_data  # Просто обновляем кеш

            current_data = database.get_script_data(client_name, project_name, script_name)
            return template('script',
                            client_name=client_name,
                            project_name=project_name,
                            script_name=script_name,
                            script_data=current_data,
                            message="Сохранено успешно" if result['status'] == 'success' else result['message'])
        else:
            # Перезагрузка страницы
            pass

    script_data = database.get_script_data(client_name, project_name, script_name)
    if script_data is None:
        return "Скрипт не найден"

    return template('script',
                    client_name=client_name,
                    project_name=project_name,
                    script_name=script_name,
                    script_data=script_data,
                    message=None)


# Raw доступ к скрипту
@route('/astral/<client_name>/<project_name>/<script_name>/raw', method=['GET', 'POST'])
def script_raw(client_name, project_name, script_name):
    script_data = database.get_script_data(client_name, project_name, script_name) or ""

    if request.method == 'POST':
        # Только raw data (быстро и без лишних проверок)
        raw_data = request.body.read()
        try:
            new_data = raw_data.decode('utf-8')
        except UnicodeDecodeError:
            new_data = raw_data.decode('latin-1')

        result = database.save_script_data(client_name, project_name, script_name, new_data)
        #latest_script_data = new_data  # Просто обновляем кеш
        return "true" if result['status'] == 'success' else ""

    return script_data

database.init_db()
#run(host='127.0.0.1', port=8000)
run(host='0.0.0.0', port=8000)