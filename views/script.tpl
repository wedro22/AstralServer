<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
    <script src="/static/ace/ace.js"></script>
    <script src="/static/ace/ext-language_tools.js"></script>
    <style>
        .editor-container {
            display: flex;
            width: 100%;
            gap: 10px;
        }
        .ace-editor {
            width: 50%;
            height: 500px;
            border: 1px solid #ccc;
        }
        .language-selector {
            margin-bottom: 10px;
        }
        select {
            padding: 5px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Скрипт: {{client_name}}/{{project_name}}/{{script_name}}</h1>

        <div class="header-actions">
            <a href="/astral/{{client_name}}/{{project_name}}" class="back-link">← Назад к списку скриптов</a>

            <div class="delete-container">
                <a href="#" class="delete-link">Удалить скрипт</a>
                <form action="/astral/{{client_name}}/{{project_name}}/{{script_name}}/action/delete" method="post" class="delete-confirm">
                    <span>Вы уверены?</span>
                    <button type="submit" class="confirm-btn">Да</button>
                    <a href="#" class="cancel-btn">Нет</a>
                </form>
            </div>
        </div>

        % if message:
            <div class="message">{{message}}</div>
        % end

        <form method="POST" class="script-form" id="scriptForm">
            <div class="language-selector">
                <select id="languageSelector"></select>
            </div>
            <div class="editor-container">
                <div id="leftEditor" class="ace-editor"></div>
                <div id="rightEditor" class="ace-editor"></div>
            </div>
            <input type="hidden" name="script_data" id="hiddenScriptData">
            <div class="form-actions">
                <button type="submit" name="save" class="primary-btn">Сохранить</button>
                <button type="button" name="reload" class="secondary-btn" id="reloadBtn">Сбросить изменения</button>
            </div>
        </form>
    </div>

    <script>
        // Объявляем переменные редакторов глобально (используется в обновлении правого редактора)
        let leftEditor, rightEditor;
        let updateInterval;

        document.addEventListener('DOMContentLoaded', function() {
            // Получаем текущий URL для использования как ключ в localStorage
            const pageKey = window.location.pathname;

            // Инициализация редакторов (используем глобальные переменные)
            leftEditor = ace.edit("leftEditor");
            rightEditor = ace.edit("rightEditor");

            // Настройка редакторов
            [leftEditor, rightEditor].forEach(editor => {
                editor.setTheme("ace/theme/chrome");
                editor.setShowPrintMargin(false);
                editor.setOptions({
                    enableBasicAutocompletion: true,
                    enableLiveAutocompletion: true,
                    enableSnippets: true
                });
            });

            // Загрузка списка языков
            fetch('/static/ace/mode-list.json')
                .then(response => response.json())
                .then(languages => {
                    const selector = document.getElementById('languageSelector');

                    // Заполняем селектор языками
                    languages.forEach(lang => {
                        const option = document.createElement('option');
                        option.value = lang;
                        option.textContent = lang;
                        selector.appendChild(option);
                    });

                    // Инициализация или загрузка сохраненных данных
                    initializeStorageAndEditors(languages);
                })
                .catch(error => console.error('Error loading languages:', error));

            function initializeStorageAndEditors(languages) {
                // Получаем или инициализируем сохраненные данные
                let savedData = localStorage.getItem(pageKey);

                if (savedData) {
                    savedData = JSON.parse(savedData);
                } else {
                    // Инициализация по умолчанию
                    savedData = {
                        language: 'lua',
                        scriptData: `{{script_data}}`
                    };
                    localStorage.setItem(pageKey, JSON.stringify(savedData));
                }

                // Устанавливаем язык
                document.getElementById('languageSelector').value = savedData.language;
                setEditorLanguage(leftEditor, savedData.language);
                setEditorLanguage(rightEditor, savedData.language);

                // Устанавливаем содержимое редакторов
                leftEditor.setValue(savedData.scriptData, -1);
                rightEditor.setValue(`{{script_data}}`, -1);

                // Обработчики событий
                setupEventHandlers();
            }

            function setEditorLanguage(editor, language) {
                editor.session.setMode(`ace/mode/${language}`);
            }

            function setupEventHandlers() {
                const selector = document.getElementById('languageSelector');
                const pageKey = window.location.pathname;

                // Изменение языка
                selector.addEventListener('change', function() {
                    const newLanguage = this.value;

                    // Обновляем редакторы
                    setEditorLanguage(leftEditor, newLanguage);
                    setEditorLanguage(rightEditor, newLanguage);

                    // Сохраняем в localStorage
                    let savedData = JSON.parse(localStorage.getItem(pageKey));
                    savedData.language = newLanguage;
                    localStorage.setItem(pageKey, JSON.stringify(savedData));
                });

                // Изменение содержимого левого редактора
                leftEditor.session.on('change', function() {
                    const content = leftEditor.getValue();
                    let savedData = JSON.parse(localStorage.getItem(pageKey));
                    savedData.scriptData = content;
                    localStorage.setItem(pageKey, JSON.stringify(savedData));
                });

                // Кнопка сохранения
                document.getElementById('scriptForm').addEventListener('submit', function(e) {
                    document.getElementById('hiddenScriptData').value = leftEditor.getValue();
                });

                // Кнопка перезагрузки
                document.getElementById('reloadBtn').addEventListener('click', function() {
                    // Обновляем localStorage из правого редактора
                    let savedData = JSON.parse(localStorage.getItem(pageKey));
                    savedData.scriptData = document.getElementById('hiddenScriptData').value;
                    localStorage.setItem(pageKey, JSON.stringify(savedData));

                    // Устанавливаем содержимое редакторов
                    leftEditor.setValue(document.getElementById('hiddenScriptData').value, -1);
                    rightEditor.setValue(document.getElementById('hiddenScriptData').value, -1);
                });
            }
        });

        //функция возвращающая сырые данные
        async function fetchScriptData() {
            try {
                const response = await fetch(window.location.pathname + '/raw');
                if (!response.ok) {
                    console.error('HTTP error:', response.status, response.statusText);
                    return null;
                }
                return await response.text();
            } catch (error) {
                console.error('Fetch failed:', error);
                return null;
            }
        }

        // Функция, устанавливающая script_data у hiddenScriptData
        function updateHiddenData() {
            fetchScriptData()
                .then(data => {
                    if (data !== null) {
                        document.getElementById('hiddenScriptData').value = data;
                        if (rightEditor && typeof rightEditor.setValue === 'function') {
                            rightEditor.setValue(data, -1);
                        } else {
                            console.warn('Right editor not initialized');
                        }
                    }
                });
        }

        // Запускаем обновление каждые 5 секунд
        updateInterval = setInterval(updateHiddenData, 5000);

        // Очистка при закрытии страницы
        window.addEventListener('beforeunload', () => clearInterval(updateInterval));
    </script>
</body>
</html>