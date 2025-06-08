# database.py
from pathlib import Path
from datetime import datetime
from pony import orm #from pony.orm import *
from pony.orm import db_session

DB_NAME = Path(__file__).parent.parent / 'astral.db'

db = orm.Database()


class Client(db.Entity):
    id = orm.PrimaryKey(int, auto=True)
    name = orm.Required(str, unique=True)
    projects = orm.Set('Project', reverse='client')
    scripts = orm.Set('Script', reverse='client')  # Добавляем обратную ссылку


class Project(db.Entity):
    id = orm.PrimaryKey(int, auto=True)
    client = orm.Required(Client, reverse='projects')
    name = orm.Required(str)
    type = orm.Optional(str, nullable=True)
    scripts = orm.Set('Script', reverse='project')  # Уже есть

    orm.composite_key(client, name)


class Script(db.Entity):
    id = orm.PrimaryKey(int, auto=True)
    project = orm.Required(Project, reverse='scripts')
    client = orm.Required(Client, reverse='scripts')  # Добавляем обратную ссылку
    name = orm.Required(str)
    data = orm.Optional(str, default='')
    result = orm.Optional(str, default='')
    script_type = orm.Optional(str, nullable=True)
    draw_x = orm.Optional(int, nullable=True)
    draw_y = orm.Optional(int, nullable=True)
    draw_style = orm.Optional(str, nullable=True)
    data_read = orm.Optional(datetime, nullable=True)

    orm.composite_key(project, name)


def init_db():
    try:
        # Подключаемся к базе данных
        db.bind(provider='sqlite', filename=str(DB_NAME), create_db=True)
        # Генерируем маппинг сущностей
        db.generate_mapping(create_tables=True)
        print("БД подключено")
    except Exception as e:
        print(f"Ошибка при подключении БД: {e}")


@db_session
def astral_client_creation(client_name: str):
    """Обрабатывает создание/проверку клиента"""
    try:
        # Пытаемся добавить клиента (если уже есть - игнорируем)
        Client.get(name=client_name) or Client(name=client_name)
        orm.commit()
        return {"status": "success", "client": client_name}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def astral_project_creation(client_name: str, project_name: str, project_type: str = None):
    """Создает новый проект для клиента"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        Project.get(client=client, name=project_name) or Project(
            client=client,
            name=project_name,
            type=project_type
        )
        orm.commit()
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def get_client_projects(client_name: str):
    """Всегда возвращает список, даже пустой"""
    client = Client.get(name=client_name)
    if not client:
        return []

    projects = orm.select(p for p in Project if p.client == client)[:]
    return [{'name': p.name, 'type': p.type} for p in projects]


@db_session
def get_project_scripts(client_name: str, project_name: str):
    """Всегда возвращает список, даже пустой"""
    client = Client.get(name=client_name)
    if not client:
        return []

    project = Project.get(client=client, name=project_name)
    if not project:
        return []

    scripts = orm.select(s for s in Script if s.project == project)[:]
    return [s.name for s in scripts]


@db_session
def get_project_type(client_name: str, project_name: str) -> str:
    """Всегда возвращает строку (пустую, если project_type не найден или ошибка)"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return ""

        project = Project.get(client=client, name=project_name)
        return project.type if project else ""
    except Exception as e:
        print(f"Error getting project type: {e}")
        return ""


@db_session
def astral_script_creation(client_name: str, project_name: str, script_name: str):
    """Создает новый скрипт в проекте"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        project = Project.get(client=client, name=project_name)
        if not project:
            return {"status": "error", "message": "Проект не найден"}

        Script.get(project=project, name=script_name) or Script(
            project=project,
            client=client,
            name=script_name
        )
        orm.commit()
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def get_script_data(client_name: str, project_name: str, script_name: str):
    """Получает данные скрипта"""
    client = Client.get(name=client_name)
    if not client:
        return None

    project = Project.get(client=client, name=project_name)
    if not project:
        return None

    script = Script.get(project=project, name=script_name)
    return script.data if script else None


@db_session
def save_script_data(client_name: str, project_name: str, script_name: str, script_data: str):
    """Сохраняет данные скрипта"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        project = Project.get(client=client, name=project_name)
        if not project:
            return {"status": "error", "message": "Проект не найден"}

        script = Script.get(project=project, name=script_name)
        if not script:
            return {"status": "error", "message": "Скрипт не найден"}

        script.data = script_data
        orm.commit()
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def get_script_result(client_name: str, project_name: str, script_name: str):
    """Получает данные результата скрипта"""
    client = Client.get(name=client_name)
    if not client:
        return None

    project = Project.get(client=client, name=project_name)
    if not project:
        return None

    script = Script.get(project=project, name=script_name)
    return script.result if script else None


@db_session
def save_script_result(client_name: str, project_name: str, script_name: str, script_result: str):
    """Сохраняет данные результата скрипта"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        project = Project.get(client=client, name=project_name)
        if not project:
            return {"status": "error", "message": "Проект не найден"}

        script = Script.get(project=project, name=script_name)
        if not script:
            return {"status": "error", "message": "Скрипт не найден"}

        script.result = script_result
        orm.commit()
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def delete_client(client_name: str):
    """Удаляет клиента и все связанные проекты и скрипты (каскадное удаление)"""
    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        client.delete()
        orm.commit()
        return {"status": "success", "message": f"Клиент '{client_name}' и все связанные данные удалены"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def delete_project(client_name: str, project_name: str):
    """Удаляет проект и все связанные скрипты (каскадное удаление)"""
    if project_name.lower() == 'action':
        return {"status": "error", "message": "Invalid project name"}

    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        project = Project.get(client=client, name=project_name)
        if not project:
            return {"status": "error", "message": "Проект не найден"}

        project.delete()
        orm.commit()
        return {"status": "success", "message": f"Проект '{project_name}' и все связанные скрипты удалены"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@db_session
def delete_script(client_name: str, project_name: str, script_name: str):
    """Удаляет скрипт"""
    if script_name.lower() == 'action':
        return {"status": "error", "message": "Invalid script name"}

    try:
        client = Client.get(name=client_name)
        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        project = Project.get(client=client, name=project_name)
        if not project:
            return {"status": "error", "message": "Проект не найден"}

        script = Script.get(project=project, name=script_name)
        if not script:
            return {"status": "error", "message": "Скрипт не найден"}

        script.delete()
        orm.commit()
        return {"status": "success", "message": f"Скрипт '{script_name}' удален"}
    except Exception as e:
        return {"status": "error", "message": str(e)}