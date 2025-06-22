from pathlib import Path
from datetime import datetime
from pony import orm
from pony.orm import db_session
from typing import List, Dict, Optional

DB_NAME = Path(__file__).parent.parent / 'astral2.db'
db = orm.Database()

def init_db():
    try:
        # Подключаемся к базе данных
        db.bind(provider='sqlite', filename=str(DB_NAME), create_db=True)
        # Генерируем маппинг сущностей
        db.generate_mapping(create_tables=True)
        print("БД подключено")
    except Exception as e:
        print(f"Ошибка при подключении БД: {e}")

class Project(db.Entity):
    """Сущность проекта."""
    id = orm.PrimaryKey(int, auto=True)
    name = orm.Required(str, unique=True)
    created = orm.Required(datetime)


# ------------------------
# Утилитарные функции
# ------------------------

def _project_to_dict(project: "Project") -> Dict:
    """Преобразует объект Project в словарь, подходящий для JSON-сериализации."""
    return {
        "id": project.id,
        "name": project.name,
        "created": project.created.strftime("%Y-%m-%d"),
    }


@db_session
def add_project(name: str, created: Optional[datetime] = None) -> Dict:
    """Добавляет новый проект и возвращает его в виде словаря."""
    created = created or datetime.utcnow()
    project = Project(name=name, created=created)
    return _project_to_dict(project)


@db_session
def list_projects() -> List[Dict]:
    """Возвращает список всех проектов отсортированных по дате создания."""
    return [_project_to_dict(p) for p in Project.select().order_by(lambda p: p.created)]