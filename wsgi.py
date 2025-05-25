import os
from bottle import Bottle, default_app
import server  # импортируем весь server.py
from bottle import TEMPLATE_PATH

# Получаем текущую директорию, где находится wsgi.py
current_dir = os.path.dirname(os.path.abspath(__file__))

# Формируем путь к папке views относительно wsgi.py
views_path = os.path.join(current_dir, "views")

# Добавляем путь в TEMPLATE_PATH
TEMPLATE_PATH.insert(0, views_path)

application = default_app()