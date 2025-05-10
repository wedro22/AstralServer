<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
    <style>
        /* Добавляем стили для редактора и переключателей */
        .editor-container {
            position: relative;
            height: 500px;
            border: 1px solid #ccc;
            margin-bottom: 10px;
        }
        #ace-editor {
            width: 100%;
            height: 100%;
        }
        .toggle-container {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .toggle-switch {
            display: flex;
            align-items: center;
        }
        .toggle-switch label {
            margin-right: 10px;
        }
        .language-selector {
            min-width: 150px;
        }
        .hidden {
            display: none;
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

        <form method="POST" class="script-form">
            <div class="toggle-container">
                <div class="toggle-switch">
                    <label for="editor-toggle">Редактор кода:</label>
                    <input type="checkbox" id="editor-toggle" checked>
                </div>
                <div>
                    <label for="language-select">Язык:</label>
                    <select id="language-select" class="language-selector">
                        <option value="lua">Lua</option>
                        <!-- Другие языки будут добавлены через JavaScript -->
                    </select>
                </div>
            </div>

            <div id="editor-container" class="editor-container">
                <div id="ace-editor"></div>
            </div>

            <textarea id="script-textarea" name="script_data" class="script-editor hidden">{{script_data}}</textarea>

            <div class="form-actions">
                <button type="submit" name="save" class="primary-btn">Сохранить</button>
                <button type="submit" name="reload" class="secondary-btn">Перезагрузить</button>
            </div>
        </form>
    </div>

    <!-- Подключаем Ace Editor -->
    <script src="/static/ace/ace.js"></script>
    <script src="/static/ace/ext-language_tools.js"></script>
    <script>
        // Инициализация редактора
        let editor;
        let editorEnabled = true;
        const textarea = document.getElementById('script-textarea');
        const editorContainer = document.getElementById('editor-container');
        const editorToggle = document.getElementById('editor-toggle');
        const languageSelect = document.getElementById('language-select');

        // Функция для сохранения данных в localStorage
        function saveToLocalStorage() {
            localStorage.setItem('scriptEditorData', editor ? editor.getValue() : textarea.value);
            localStorage.setItem('scriptEditorEnabled', editorToggle.checked);
            localStorage.setItem('scriptEditorLanguage', languageSelect.value);
        }

        // Функция для загрузки данных из localStorage
        function loadFromLocalStorage() {
            const savedData = localStorage.getItem('scriptEditorData');
            const savedEnabled = localStorage.getItem('scriptEditorEnabled');
            const savedLanguage = localStorage.getItem('scriptEditorLanguage');

            if (savedData !== null) {
                if (editor) {
                    editor.setValue(savedData);
                }
                textarea.value = savedData;
            }

            if (savedEnabled !== null) {
                editorToggle.checked = savedEnabled === 'true';
                toggleEditor();
            }

            if (savedLanguage !== null) {
                languageSelect.value = savedLanguage;
                if (editor) {
                    editor.session.setMode(`ace/mode/${savedLanguage}`);
                }
            }
        }

        // Функция для переключения между редактором и текстовым полем
        function toggleEditor() {
            editorEnabled = editorToggle.checked;

            if (editorEnabled) {
                // Включаем редактор
                editorContainer.classList.remove('hidden');
                textarea.classList.add('hidden');

                // Переносим текст из textarea в редактор
                if (editor) {
                    editor.setValue(textarea.value);
                }
            } else {
                // Выключаем редактор
                editorContainer.classList.add('hidden');
                textarea.classList.remove('hidden');

                // Переносим текст из редактора в textarea
                if (editor) {
                    textarea.value = editor.getValue();
                }
            }

            saveToLocalStorage();
        }

        // Инициализация редактора при загрузке страницы
        function initEditor() {
            editor = ace.edit("ace-editor");
            editor.setTheme("ace/theme/chrome");
            editor.session.setMode("ace/mode/lua");
            editor.setOptions({
                enableBasicAutocompletion: true,
                enableLiveAutocompletion: true,
                fontSize: "14px"
            });

            // Устанавливаем начальное значение
            editor.setValue(textarea.value);

            // Сохраняем изменения при редактировании
            editor.on('change', function() {
                saveToLocalStorage();
            });

            // Загружаем список языков с сервера
            fetch('/static/ace/mode-list.json')
                .then(response => response.json())
                .then(languages => {
                    languages.forEach(lang => {
                        if (lang !== 'lua') {
                            const option = document.createElement('option');
                            option.value = lang;
                            option.textContent = lang;
                            languageSelect.appendChild(option);
                        }
                    });
                })
                .catch(() => {
                    // Если не удалось загрузить список, добавляем основные языки
                    const commonLanguages = ['javascript', 'python', 'java', 'c_cpp', 'php', 'ruby', 'sh', 'sql', 'xml', 'html', 'css'];
                    commonLanguages.forEach(lang => {
                        if (lang !== 'lua') {
                            const option = document.createElement('option');
                            option.value = lang;
                            option.textContent = lang;
                            languageSelect.appendChild(option);
                        }
                    });
                });

            // Обработчик изменения языка
            languageSelect.addEventListener('change', function() {
                editor.session.setMode(`ace/mode/${this.value}`);
                saveToLocalStorage();
            });

            // Обработчик переключения редактора
            editorToggle.addEventListener('change', toggleEditor);

            // Обработчик изменений в textarea
            textarea.addEventListener('input', saveToLocalStorage);

            // Загружаем сохраненные данные
            loadFromLocalStorage();
        }

        // Инициализируем редактор, если JavaScript включен
        document.addEventListener('DOMContentLoaded', function() {
            // Если JavaScript отключен, показываем textarea
            textarea.classList.remove('hidden');
            editorContainer.classList.add('hidden');

            // Инициализируем редактор
            initEditor();

            // Обработчик формы для сохранения текущего состояния
            document.querySelector('.script-form').addEventListener('submit', function(e) {
                // При отправке формы синхронизируем данные
                if (editorEnabled) {
                    textarea.value = editor.getValue();
                } else {
                    if (editor) {
                        editor.setValue(textarea.value);
                    }
                }
                saveToLocalStorage();
            });

            // Обработчик кнопки "Перезагрузить"
            document.querySelector('button[name="reload"]').addEventListener('click', function(e) {
                e.preventDefault();
                fetch(window.location.href)
                    .then(response => response.text())
                    .then(html => {
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(html, 'text/html');
                        const newScriptData = doc.querySelector('.script-editor').textContent;

                        if (editor) {
                            editor.setValue(newScriptData);
                        }
                        textarea.value = newScriptData;
                        saveToLocalStorage();
                    })
                    .catch(error => {
                        console.error('Ошибка при перезагрузке:', error);
                        loadFromLocalStorage(); // Восстанавливаем из локального хранилища
                    });
            });
        });
    </script>
</body>
</html>