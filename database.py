# database.py
import sqlite3
from sqlite3 import Error
DB_NAME='astral.db'


def init_db():
    connection = None
    try:
        # Добавляем параметр detect_types для корректной работы с Unicode
        connection = sqlite3.connect(DB_NAME, detect_types=sqlite3.PARSE_DECLTYPES)
        connection.execute("PRAGMA encoding = 'UTF-8'")  # Явно указываем кодировку
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


def get_db():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn


def astral_client_creation(client_name):
    """Обрабатывает создание/проверку клиента"""
    conn = None
    try:
        # Проверяем, что client_name - это строка в Unicode
        if not isinstance(client_name, str):
            client_name = str(client_name, 'utf-8')  # Конвертируем из bytes если нужно

        conn = get_db()
        # Пытаемся добавить клиента (если уже есть - игнорируем)
        conn.execute('INSERT OR IGNORE INTO clients (client_name) VALUES (?)', (client_name,))
        conn.commit()
        return {"status": "success", "client": client_name}
    except sqlite3.IntegrityError as e:
        return {"status": "error", "message": str(e)}
    except Exception as e:
        return {"status": "error", "message": f"Database error: {str(e)}"}
    finally:
        if conn:
            conn.close()


def get_client_projects(client_name):
    """Получает список проектов клиента"""
    conn = get_db()
    try:
        client = conn.execute(
            'SELECT client_id FROM clients WHERE client_name = ?',
            (client_name,)
        ).fetchone()

        if not client:
            return None

        projects = conn.execute(
            'SELECT project_name FROM projects WHERE client_id = ?',
            (client['client_id'],)
        ).fetchall()

        return [p['project_name'] for p in projects]
    finally:
        conn.close()


def astral_project_creation(client_name, project_name):
    """Создает новый проект для клиента"""
    conn = None
    try:
        if not isinstance(project_name, str):
            project_name = str(project_name, 'utf-8')

        conn = get_db()
        client = conn.execute(
            'SELECT client_id FROM clients WHERE client_name = ?',
            (client_name,)
        ).fetchone()

        if not client:
            return {"status": "error", "message": "Клиент не найден"}

        conn.execute(
            'INSERT INTO projects (client_id, project_name) VALUES (?, ?)',
            (client['client_id'], project_name)
        )
        conn.commit()
        return {"status": "success"}
    except sqlite3.IntegrityError as e:
        return {"status": "error", "message": str(e)}
    finally:
        if conn:
            conn.close()


def get_project_scripts(client_name, project_name):
    """Получает список скриптов проекта"""
    conn = get_db()
    try:
        project = conn.execute('''
            SELECT p.project_id 
            FROM projects p
            JOIN clients c ON p.client_id = c.client_id
            WHERE c.client_name = ? AND p.project_name = ?
        ''', (client_name, project_name)).fetchone()

        if not project:
            return None

        scripts = conn.execute(
            'SELECT script_name FROM scripts WHERE project_id = ?',
            (project['project_id'],)
        ).fetchall()

        return [s['script_name'] for s in scripts]
    finally:
        conn.close()


def astral_script_creation(client_name, project_name, script_name):
    """Создает новый скрипт в проекте"""
    conn = None
    try:
        if not isinstance(script_name, str):
            script_name = str(script_name, 'utf-8')

        conn = get_db()
        project = conn.execute('''
            SELECT p.project_id 
            FROM projects p
            JOIN clients c ON p.client_id = c.client_id
            WHERE c.client_name = ? AND p.project_name = ?
        ''', (client_name, project_name)).fetchone()

        if not project:
            return {"status": "error", "message": "Проект не найден"}

        conn.execute(
            'INSERT INTO scripts (project_id, script_name) VALUES (?, ?)',
            (project['project_id'], script_name)
        )
        conn.commit()
        return {"status": "success"}
    except sqlite3.IntegrityError as e:
        return {"status": "error", "message": str(e)}
    finally:
        if conn:
            conn.close()


def get_script_data(client_name, project_name, script_name):
    """Получает данные скрипта"""
    conn = get_db()
    try:
        script = conn.execute('''
            SELECT s.script_data 
            FROM scripts s
            JOIN projects p ON s.project_id = p.project_id
            JOIN clients c ON p.client_id = c.client_id
            WHERE c.client_name = ? AND p.project_name = ? AND s.script_name = ?
        ''', (client_name, project_name, script_name)).fetchone()

        return script['script_data'] if script else None
    finally:
        conn.close()


def save_script_data(client_name, project_name, script_name, script_data):
    """Сохраняет данные скрипта"""
    conn = None
    try:
        conn = get_db()
        conn.execute('''
            UPDATE scripts
            SET script_data = ?
            WHERE script_id IN (
                SELECT s.script_id
                FROM scripts s
                JOIN projects p ON s.project_id = p.project_id
                JOIN clients c ON p.client_id = c.client_id
                WHERE c.client_name = ? AND p.project_name = ? AND s.script_name = ?
            )
        ''', (script_data, client_name, project_name, script_name))
        conn.commit()
        return {"status": "success"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        if conn:
            conn.close()