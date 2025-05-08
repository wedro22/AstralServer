# database.py
import sqlite3
from sqlite3 import Error

def init_db():
    connection = None
    try:
        connection = sqlite3.connect('astral.db')
        cursor = connection.cursor()

        # Включаем поддержку внешних ключей
        cursor.execute("PRAGMA foreign_keys = ON")

        # Таблица clients (клиенты)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS clients (
                client_id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_name TEXT UNIQUE NOT NULL
            )
            ''')

        # Таблица projects (проекты)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS projects (
                project_id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_id INTEGER NOT NULL,
                project_name TEXT NOT NULL,
                FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE,
                UNIQUE(client_id, project_name)
            )
            ''')

        # Таблица scripts (скрипты)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS scripts (
                script_id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER NOT NULL,
                script_name TEXT NOT NULL,
                script_data TEXT NOT NULL DEFAULT '',
                FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE,
                UNIQUE(project_id, script_name)
            )
            ''')

        print("БД подключено")
        connection.commit()

    except Error as e:

        print(f"Ошибка при подключении БД: {e}")

    finally:

        if connection:
            connection.close()


def add_client(client_name):
    conn = sqlite3.connect('astral.db')
    c = conn.cursor()
    c.execute("INSERT OR IGNORE INTO clients (client_name) VALUES (?)", (client_name,))
    conn.commit()
    conn.close()