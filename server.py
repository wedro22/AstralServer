# server.py
from bottle import route, run, request, post, get, default_app, static_file, template, redirect
from database import init_db, astral_client_creation, get_client_projects, astral_project_creation, get_project_scripts, \
    astral_script_creation, save_script_data, get_script_data

init_db()

@route('/')
def hello():
    return "Пыщ!"

@post('/echo')
def echo():
    return 'You sent: ' + request.body.read().decode('utf-8')

@route('/static/<filename:path>')   # Статические файлы (CSS, JS) style.css
def serve_static(filename):
    return static_file(filename, root='./static')


@route('/astral', method=['GET', 'POST'])
def astral():
    if request.method == 'POST':
        client_name = request.forms.getunicode('client_name', '').strip()   # Используем getunicode вместо get

        if not client_name:
            return template('astral', error="Имя клиента не может быть пустым")

        result = astral_client_creation(client_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}")
        else:
            return template('astral', error=result['message'])

    return template('astral')


@route('/astral/<client_name>', method=['GET', 'POST'])
def client_page(client_name):
    if request.method == 'POST':
        project_name = request.forms.getunicode('project_name', '').strip()

        if not project_name:
            projects = get_client_projects(client_name)
            return template('client',
                            client_name=client_name,
                            projects=projects,
                            error="Имя проекта не может быть пустым")

        result = astral_project_creation(client_name, project_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}/{project_name}")
        else:
            projects = get_client_projects(client_name)
            return template('client',
                            client_name=client_name,
                            projects=projects,
                            error=result['message'])

    projects = get_client_projects(client_name)
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
            scripts = get_project_scripts(client_name, project_name)
            return template('project',
                            client_name=client_name,
                            project_name=project_name,
                            scripts=scripts,
                            error="Имя скрипта не может быть пустым")

        result = astral_script_creation(client_name, project_name, script_name)

        if result['status'] == 'success':
            return redirect(f"/astral/{client_name}/{project_name}/{script_name}")
        else:
            scripts = get_project_scripts(client_name, project_name)
            return template('project',
                            client_name=client_name,
                            project_name=project_name,
                            scripts=scripts,
                            error=result['message'])

    scripts = get_project_scripts(client_name, project_name)
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
            result = save_script_data(client_name, project_name, script_name, script_data)

            current_data = get_script_data(client_name, project_name, script_name)
            return template('script',
                            client_name=client_name,
                            project_name=project_name,
                            script_name=script_name,
                            script_data=current_data,
                            message="Сохранено успешно" if result['status'] == 'success' else result['message'])
        else:
            # Перезагрузка страницы
            pass

    script_data = get_script_data(client_name, project_name, script_name)
    if script_data is None:
        return "Скрипт не найден"

    return template('script',
                    client_name=client_name,
                    project_name=project_name,
                    script_name=script_name,
                    script_data=script_data,
                    message=None)

run(host='127.0.0.1', port=8000)