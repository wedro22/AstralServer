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
    type = orm.Optional(str, nullable=True)
    draw_x = orm.Optional(int, nullable=True)
    draw_y = orm.Optional(int, nullable=True)
    draw_style = orm.Optional(str, nullable=True)
    last_reading = orm.Optional(datetime, nullable=True)
    next_scripts = orm.Optional(str, default='')

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
def astral_script_creation(
        client_name: str,
        project_name: str,
        script_name: str,
        **kwargs
) -> dict:
    """
    Создает новый скрипт в существующем проекте.

    Обязательные параметры:
    - client_name: имя существующего клиента
    - project_name: имя существующего проекта
    - script_name: имя создаваемого скрипта

    Опциональные параметры (kwargs):
    - data: содержимое скрипта
    - result: результат выполнения
    - type: тип скрипта
    - draw_x: координата X для отображения
    - draw_y: координата Y для отображения
    - draw_style: стиль отображения
    - last_reading: дата последнего чтения
    - next_scripts: список следующих скриптов

    Возвращает словарь с ключами:
    - status: "success" или "error"
    - message: дополнительное сообщение (при ошибке)
    """
    try:
        # Проверяем существование клиента
        client = Client.get(name=client_name)
        if not client:
            return {
                "status": "error",
                "message": f"Клиент '{client_name}' не найден"
            }

        # Проверяем существование проекта у этого клиента
        project = Project.get(client=client, name=project_name)
        if not project:
            return {
                "status": "error",
                "message": f"Проект '{project_name}' не найден у клиента '{client_name}'"
            }

        # Проверяем, не существует ли уже скрипт с таким именем
        existing_script = Script.get(project=project, name=script_name)
        if existing_script:
            return {
                "status": "error",
                "message": f"Скрипт '{script_name}' уже существует в проекте"
            }

        # Создаем новый скрипт с переданными параметрами
        script = Script(
            project=project,
            client=client,
            name=script_name,
            **{k: v for k, v in kwargs.items() if hasattr(Script, k)}
        )

        orm.commit()

        return {
            "status": "success",
            "message": "Скрипт успешно создан",
        }

    except Exception as e:
        return {
            "status": "error",
            "message": f"Ошибка при создании скрипта: {str(e)}"
        }


@db_session
def astral_script_update(
        client_name: str,
        project_name: str,
        script_name: str,
        **kwargs
) -> dict:
    """
    Обновляет свойства существующего скрипта.

    Обязательные параметры:
    - client_name: имя клиента
    - project_name: имя проекта
    - script_name: имя скрипта

    Опциональные параметры (kwargs):
    - Любые свойства класса Script для обновления:
      data, result, type, draw_x, draw_y, draw_style,
      last_reading, next_scripts и другие

    Возвращает словарь с ключами:
    - status: "success" или "error"
    - message: дополнительное сообщение
    """
    try:
        # Проверяем существование клиента
        client = Client.get(name=client_name)
        if not client:
            return {
                "status": "error",
                "message": f"Клиент '{client_name}' не найден"
            }

        # Проверяем существование проекта
        project = Project.get(client=client, name=project_name)
        if not project:
            return {
                "status": "error",
                "message": f"Проект '{project_name}' не найден у клиента '{client_name}'"
            }

        # Находим скрипт
        script = Script.get(project=project, name=script_name)
        if not script:
            return {
                "status": "error",
                "message": f"Скрипт '{script_name}' не найден в проекте"
            }

        # Фильтруем kwargs, оставляя только допустимые атрибуты
        valid_attrs = {k: v for k, v in kwargs.items() if hasattr(Script, k)}

        if not valid_attrs:
            return {
                "status": "error",
                "message": "Не указано ни одного допустимого поля для обновления"
            }

        # Обновляем поля
        updated_fields = []
        for attr, value in valid_attrs.items():
            setattr(script, attr, value)
            updated_fields.append(attr)

        orm.commit()

        return {
            "status": "success",
            "message": "Свойства скрипта успешно обновлены",
        }

    except Exception as e:
        return {
            "status": "error",
            "message": f"Ошибка при обновлении скрипта: {str(e)}"
        }


@db_session
def get_script_properties(
        client_name: str,
        project_name: str,
        script_name: str
) -> dict:
    """
    Получает свойства скрипта и возвращает их в одном словаре.

    Возвращает словарь с ключами:
    - status: "success" или "error"
    - message: информационное сообщение
    - Все остальные поля скрипта (id, name, data, type и т.д.)
    """
    result = {"status": "error", "message": "Неизвестная ошибка"}

    try:
        # Проверяем цепочку клиент -> проект -> скрипт
        client = Client.get(name=client_name)
        if not client:
            result["message"] = "Клиент не найден"
            return result

        project = Project.get(client=client, name=project_name)
        if not project:
            result["message"] = "Проект не найден"
            return result

        script = Script.get(project=project, name=script_name)
        if not script:
            result["message"] = "Скрипт не найден"
            return result

        # Получаем все атрибуты скрипта, исключая служебные
        script_attrs = [attr for attr in dir(script.__class__)
                        if not attr.startswith('_') and not callable(getattr(script.__class__, attr))]

        # Добавляем поля скрипта в результат
        for attr in script_attrs:
            value = getattr(script, attr)
            if attr == 'last_reading' and value:
                value = value.isoformat()
            result[attr] = value

        result.update({
            "status": "success",
            "message": "Данные скрипта успешно получены"
        })

    except Exception as e:
        result["message"] = f"Ошибка при получении скрипта: {str(e)}"

    return result


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