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
# Целевая директория на сервере (где лежит и сам скрипт)
TARGET_DIR="$(dirname "$0")"  # Автоматически определяет папку скрипта

# Копируем скрипт во временную папку, чтобы он не удалился при rsync
BACKUP_SCRIPT="/tmp/update_astral_backup.sh"
cp "$0" "$BACKUP_SCRIPT"
chmod +x "$BACKUP_SCRIPT"

# Очищаем временную директорию
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Клонируем репозиторий (только последнюю версию)
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"

# Удаляем папку .git
rm -rf "$TEMP_DIR/.git"

# Копируем файлы с заменой (игнорируя сам скрипт, если он в папке)
rsync -a --delete --exclude="$(basename "$0")" "$TEMP_DIR/" "$TARGET_DIR/"

# Очищаем временную директорию
rm -rf "$TEMP_DIR"

echo "Проект успешно обновлен в $TARGET_DIR"

# Запускаем резервную копию скрипта (если он был перезаписан)
if [ -f "$TARGET_DIR/$(basename "$0")" ]; then
    mv "$BACKUP_SCRIPT" "$TARGET_DIR/$(basename "$0")"
else
    rm "$BACKUP_SCRIPT"
fi