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
                <button type="button" name="reload" class="secondary-btn" id="reloadBtn">Перезагрузить</button>
            </div>
        </form>
    </div>

    <script>
        // Глобальные переменные для редакторов
        let leftEditor, rightEditor;

        // Основная функция инициализации
        document.addEventListener('DOMContentLoaded', function() {
            const pageKey = window.location.pathname;

            // Инициализация редакторов
            leftEditor = ace.edit("leftEditor");
            rightEditor = ace.edit("rightEditor");

            configureEditors([leftEditor, rightEditor]);

            // Загрузка списка языков и инициализация
            fetch('/static/ace/mode-list.json')
                .then(response => response.json())
                .then(initializeApplication)
                .catch(error => console.error('Error loading languages:', error));

            // Загрузка актуальных данных с сервера
            fetchLatestData();
        });

        // Конфигурация редакторов
        function configureEditors(editors) {
            editors.forEach(editor => {
                editor.setTheme("ace/theme/chrome");
                editor.setShowPrintMargin(false);
                editor.setOptions({
                    enableBasicAutocompletion: true,
                    enableLiveAutocompletion: true,
                    enableSnippets: true
                });
            });
        }

        // Инициализация приложения
        function initializeApplication(languages) {
            const pageKey = window.location.pathname;
            const selector = document.getElementById('languageSelector');

            // Заполнение селектора языками
            languages.forEach(lang => {
                const option = document.createElement('option');
                option.value = lang;
                option.textContent = lang;
                selector.appendChild(option);
            });

            // Загрузка или создание сохраненных данных
            const savedData = getSavedData(pageKey);

            // Установка языка и содержимого
            setApplicationState(savedData);

            // Настройка обработчиков событий
            setupEventHandlers(pageKey, selector);
        }

        // Получение сохраненных данных
        function getSavedData(pageKey) {
            let savedData = localStorage.getItem(pageKey);

            if (!savedData) {
                savedData = {
                    language: 'lua',
                    scriptData: `{{script_data}}`
                };
                localStorage.setItem(pageKey, JSON.stringify(savedData));
            } else {
                savedData = JSON.parse(savedData);
            }

            return savedData;
        }

        // Установка состояния приложения
        function setApplicationState(savedData) {
            document.getElementById('languageSelector').value = savedData.language;
            setEditorLanguage(leftEditor, savedData.language);
            setEditorLanguage(rightEditor, savedData.language);

            leftEditor.setValue(savedData.scriptData, -1);
            rightEditor.setValue(`{{script_data}}`, -1);
        }

        // Установка языка редактора
        function setEditorLanguage(editor, language) {
            editor.session.setMode(`ace/mode/${language}`);
        }

        // Настройка обработчиков событий
        function setupEventHandlers(pageKey, selector) {
            // Изменение языка
            selector.addEventListener('change', function() {
                const newLanguage = this.value;
                updateEditorLanguage(newLanguage, pageKey);
            });

            // Изменение содержимого левого редактора
            leftEditor.session.on('change', function() {
                updateLocalStorage(pageKey, leftEditor.getValue());
            });

            // Кнопка сохранения
            document.getElementById('scriptForm').addEventListener('submit', function(e) {
                document.getElementById('hiddenScriptData').value = leftEditor.getValue();
            });

            // Кнопка перезагрузки
            document.getElementById('reloadBtn').addEventListener('click', fetchLatestData);
        }

        // Обновление языка редакторов
        function updateEditorLanguage(language, pageKey) {
            setEditorLanguage(leftEditor, language);
            setEditorLanguage(rightEditor, language);

            // Обновление localStorage
            const savedData = JSON.parse(localStorage.getItem(pageKey));
            savedData.language = language;
            localStorage.setItem(pageKey, JSON.stringify(savedData));
        }

        // Обновление localStorage
        function updateLocalStorage(pageKey, data) {
            const savedData = JSON.parse(localStorage.getItem(pageKey));
            savedData.scriptData = data;
            localStorage.setItem(pageKey, JSON.stringify(savedData));
        }

        // Получение актуальных данных с сервера
        async function fetchLatestData() {
            try {
                const response = await fetch(window.location.pathname + '/updates');
                const data = await response.text();

                if (data) {
                    rightEditor.setValue(data, -1);
                    leftEditor.setValue(data, -1);
                    updateLocalStorage(window.location.pathname, data);
                }
            } catch (error) {
                console.error('Ошибка при загрузке данных:', error);
            }
        }
    </script>
</body>
</html>