#!/bin/bash

# Проверяем, есть ли права на выполнение, и если нет - добавляем
if [ ! -x "$0" ]; then
    chmod +x "$0"
    echo "Добавлены права на выполнение. Запустите скрипт снова."
    exit 0
fi

# URL репозитория
REPO_URL="https://github.com/wedro22/AstralServer"
# Временная директория для загрузки
TEMP_DIR="/tmp/AstralServer_temp"
# Целевая директория на сервере
TARGET_DIR="/home/wedro22/AstralServer"  # ЗАМЕНИТЕ НА АКТУАЛЬНЫЙ ПУТЬ!

# Проверяем, существует ли временная директория, и очищаем её
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Создаем временную директорию
mkdir -p "$TEMP_DIR"

# Клонируем репозиторий (только последнюю версию, без истории)
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"

# Удаляем папку .git
rm -rf "$TEMP_DIR/.git"

# Проверяем целевую директорию и создаем при необходимости
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# Копируем файлы с заменой
rsync -a --delete "$TEMP_DIR/" "$TARGET_DIR/"

# Очищаем временную директорию
rm -rf "$TEMP_DIR"

echo "Проект успешно обновлен в $TARGET_DIR"