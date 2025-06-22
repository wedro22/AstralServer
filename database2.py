from pathlib import Path
from datetime import datetime
from pony import orm
from pony.orm import db_session

DB_NAME = Path(__file__).parent.parent / 'astral2.db'
db = orm.Database()

class Project(db.Entity):
    """Модель проекта"""
    id = orm.PrimaryKey(int, auto=True)
    name = orm.Required(str, unique=True)  # Уникальное имя проекта
    created_at = orm.Required(datetime, default=datetime.now)  # Дата создания
    scripts = orm.Set('Script')  # Связь с скриптами (один ко многим)
    
    def before_insert(self):
        """Хук, который срабатывает перед созданием записи"""
        self.created_at = datetime.now()

class Script(db.Entity):
    """Модель скрипта"""
    id = orm.PrimaryKey(int, auto=True)
    name = orm.Required(str)  # Имя скрипта
    project = orm.Required(Project)  # Связь с проектом
    modified_at = orm.Required(datetime, default=datetime.now)  # Дата изменения
    read_at = orm.Optional(datetime)  # Дата чтения (необязательное)
    prefix = orm.Optional(str, default="")  # Префикс (текст)
    data = orm.Optional(str, default="")  # Данные (текст)
    postfix = orm.Optional(str, default="")  # Постфикс (текст)
    result = orm.Optional(str, default="")  # Результат (текст)
    draw_x = orm.Optional(int)  # Координата X для отрисовки (целое число)
    draw_y = orm.Optional(int)  # Координата Y для отрисовки (целое число)
    draw_data = orm.Optional(str, default="")  # Данные для отрисовки (текст)
    
    # Составной уникальный ключ: имя скрипта должно быть уникальным в пределах проекта
    orm.composite_key(name, project)
    
    def before_update(self):
        """Хук, который срабатывает перед обновлением записи"""
        # Проверяем, изменились ли поля data, prefix, postfix
        if self.is_modified('data') or self.is_modified('prefix') or self.is_modified('postfix'):
            self.modified_at = datetime.now()

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
def create_project(name: str):
    """Создает новый проект"""
    if Project.get(name=name):
        raise ValueError(f"Проект с именем '{name}' уже существует.")
    return Project(name=name)

@db_session
def create_script(project_name: str, script_name: str, **kwargs):
    """Создает новый скрипт в проекте"""
    project = Project.get(name=project_name)
    if not project:
        raise ValueError(f"Проект с именем '{project_name}' не найден.")
    if Script.get(name=script_name, project=project):
        raise ValueError(f"Скрипт с именем '{script_name}' уже существует в проекте '{project_name}'.")
    
    return Script(name=script_name, project=project, **kwargs)

@db_session
def delete_project(name: str):
    """Удаляет проект и все его скрипты"""
    project = Project.get(name=name)
    if project:
        project.delete()
        return True
    return False

@db_session
def delete_script(project_name: str, script_name: str):
    """Удаляет скрипт из проекта"""
    script = Script.get(project=Project.get(name=project_name), name=script_name)
    if script:
        script.delete()
        return True
    return False

@db_session
def get_all_projects():
    """Возвращает список всех проектов в виде словарей"""
    projects = Project.select()
    return [{'name': p.name, 'created_at': p.created_at.isoformat()} for p in projects]