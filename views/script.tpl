<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
    <script src="/static/ace/ace.js"></script>
    <script src="/static/ace/ext-language_tools.js"></script>
    <style>
        select {
            padding: 5px;
            font-size: 14px;
        }
        .container {
            min-width: 900px;
            max-width: 100%;
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
                <div class="progress-container">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
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
                    enableSnippets: true,
                    showFoldWidgets: true
                });
            });
            // Делаем правый редактор только для чтения
            rightEditor.setReadOnly(true);
            rightEditor.container.classList.add("readonly-editor");

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
                        scriptData: `{{!script_data}}`
                    };
                    localStorage.setItem(pageKey, JSON.stringify(savedData));
                }

                // Устанавливаем язык
                document.getElementById('languageSelector').value = savedData.language;
                setEditorLanguage(leftEditor, savedData.language);
                setEditorLanguage(rightEditor, savedData.language);

                // Устанавливаем содержимое редакторов
                leftEditor.setValue(savedData.scriptData, -1);
                rightEditor.setValue(`{{!script_data}}`, -1);
                leftEditor.focus();

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
                //document.getElementById('scriptForm').addEventListener('submit', function(e) {
                //   document.getElementById('hiddenScriptData').value = leftEditor.getValue();
                //});

                // Кнопка сохранения
                document.getElementById('scriptForm').addEventListener('submit', function(e) {
                    e.preventDefault(); // Это важно - предотвращаем стандартную отправку формы

                    // Получаем данные из редактора
                    const scriptData = leftEditor.getValue();
                    document.getElementById('hiddenScriptData').value = scriptData;

                    // Создаем FormData и добавляем параметр save
                    const formData = new FormData();
                    formData.append('script_data', scriptData);
                    formData.append('save', 'true'); // Добавляем параметр save

                    fetch(window.location.pathname, {
                        method: 'POST',
                        body: formData
                    })
                    .then(response => {
                        if (response.ok) {
                            // Обновляем правый редактор и показываем сообщение
                            updateHiddenData();
                            window.location.reload(); // Перезагружаем страницу для обновления сообщения
                        } else {
                            return response.text().then(text => { throw new Error(text) });
                        }
                    })
                    .catch(error => {
                        console.error('Error saving script:', error);
                        alert('Ошибка сохранения: ' + error.message);
                    });
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
                    leftEditor.focus();
                });
            }
        });

        //функция возвращающая сырые данные
        async function fetchScriptData() {
            try {
                const response = await fetch(window.location.pathname + '/raw');
                if (!response.ok) {
                    console.error('HTTP error:', response.status, response.statusText);
                    return null; // Ошибка HTTP (404, 500 и т. д.)
                }
                const data = await response.text(); // Читаем тело ответа ОДИН РАЗ
                return data === null ? "" : data;   // Если null → "", иначе исходные данные
            } catch (error) {
                console.error('Fetch failed:', error);
                return null; // Ошибка сети или другая проблема
            }
        }

        // Функция, устанавливающая script_data у hiddenScriptData
        function updateHiddenData() {
            const progressFill = document.getElementById('progressFill');

            // Сбрасываем и запускаем анимацию
            progressFill.style.width = '0%';
            progressFill.classList.remove('error');

            // Плавное заполнение за 4.5 секунд (чтобы завершилось до следующего вызова)
            let start = Date.now();
            const animate = () => {
                let progress = (Date.now() - start) / 4500 * 100;
                if (progress > 100) progress = 100;
                progressFill.style.width = progress + '%';
                if (progress < 100) requestAnimationFrame(animate);
            };
            requestAnimationFrame(animate);

            // Загрузка данных
            fetchScriptData()
                .then(data => {
                    // Если data === null, значит, была ошибка в fetchScriptData()
                    if (data == null) {
                        console.error("Данные не получены из-за ошибки сервера");
                        progressFill.classList.add('error'); // Показываем ошибку
                        return;
                    }

                    // Если data === "" — это валидный пустой ответ
                    document.getElementById('hiddenScriptData').value = data;
                    if (rightEditor) {
                        const session = rightEditor.session;
                        const selection = rightEditor.selection.toJSON(); // Сохраняем текущее выделение
                        rightEditor.setValue(data, -1);
                        rightEditor.selection.fromJSON(selection); // Восстанавливаем выделение
                    }
                })
                .catch(error => {
                    progressFill.classList.add('error');
                    console.error('Update failed:', error);
                });
        }

        // Запускаем обновление каждые 5 секунд
        updateHiddenData();
        updateInterval = setInterval(updateHiddenData, 5000);

        // Очистка при закрытии страницы
        window.addEventListener('beforeunload', () => clearInterval(updateInterval));
    </script>
</body>
</html>