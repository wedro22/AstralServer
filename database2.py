from pathlib import Path
from datetime import datetime
from pony import orm
from pony.orm import db_session

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