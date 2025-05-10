<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
    <style>
        .editor-container {
            position: relative;
            height: 500px;
            border: 1px solid #ccc;
        }
        #ace-editor {
            width: 100%;
            height: 100%;
        }
        .editor-controls {
            margin: 10px 0;
            display: flex;
            gap: 15px;
            align-items: center;
        }
        .editor-toggle {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .language-selector {
            flex-grow: 1;
        }
        select {
            padding: 5px;
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
            <div class="editor-controls">
                <div class="editor-toggle">
                    <input type="checkbox" id="editor-toggle" checked>
                    <label for="editor-toggle">Редактор кода</label>
                </div>
                <div class="language-selector">
                    <select id="language-select">
                        <!-- Languages will be loaded from mode-list.json -->
                    </select>
                </div>
            </div>

            <div class="editor-container">
                <div id="ace-editor"></div>
                <textarea name="script_data" id="script-textarea" class="script-editor hidden">{{script_data}}</textarea>
            </div>

            <div class="form-actions">
                <button type="submit" name="save" class="primary-btn">Сохранить</button>
                <button type="button" id="reload-btn" class="secondary-btn">Перезагрузить</button>
            </div>
        </form>
    </div>

    <script src="/static/ace/ace.js"></script>
    <script>
        // Load mode list and initialize editor
        document.addEventListener('DOMContentLoaded', function() {
            // Load saved data from localStorage
            const savedData = localStorage.getItem('scriptEditorData');
            const savedLanguage = localStorage.getItem('scriptEditorLanguage');
            const savedEditorState = localStorage.getItem('scriptEditorEnabled');

            // Get elements
            const editorToggle = document.getElementById('editor-toggle');
            const textarea = document.getElementById('script-textarea');
            const languageSelect = document.getElementById('language-select');
            const reloadBtn = document.getElementById('reload-btn');

            // Initialize editor state
            const editorEnabled = savedEditorState !== null ? savedEditorState === 'true' : true;
            editorToggle.checked = editorEnabled;

            // Initialize Ace Editor
            const editor = ace.edit("ace-editor");
            editor.setTheme("ace/theme/chrome");
            editor.session.setUseWrapMode(true);

            // Set initial mode (language)
            let initialMode = 'lua';
            if (savedLanguage) {
                initialMode = savedLanguage;
            }
            editor.session.setMode(`ace/mode/${initialMode}`);

            // Load mode list
            fetch('/static/ace/mode-list.json')
                .then(response => response.json())
                .then(modes => {
                    modes.forEach(mode => {
                        const option = document.createElement('option');
                        option.value = mode;
                        option.textContent = mode;
                        if (mode === initialMode) {
                            option.selected = true;
                        }
                        languageSelect.appendChild(option);
                    });
                });

            // Set initial content
            if (savedData) {
                editor.setValue(savedData);
                textarea.value = savedData;
            } else {
                editor.setValue(textarea.value);
            }

            // Toggle between editor and textarea
            function toggleEditor() {
                const isEditorEnabled = editorToggle.checked;

                if (isEditorEnabled) {
                    // Switch to editor - copy text from textarea
                    editor.setValue(textarea.value);
                    document.getElementById('ace-editor').classList.remove('hidden');
                    textarea.classList.add('hidden');
                } else {
                    // Switch to textarea - copy text from editor
                    textarea.value = editor.getValue();
                    document.getElementById('ace-editor').classList.add('hidden');
                    textarea.classList.remove('hidden');
                }

                localStorage.setItem('scriptEditorEnabled', isEditorEnabled);
            }

            editorToggle.addEventListener('change', toggleEditor);

            // Initialize visibility
            toggleEditor();

            // Handle language change
            languageSelect.addEventListener('change', function() {
                const mode = this.value;
                editor.session.setMode(`ace/mode/${mode}`);
                localStorage.setItem('scriptEditorLanguage', mode);
            });

            // Save content on change
            editor.session.on('change', function() {
                localStorage.setItem('scriptEditorData', editor.getValue());
                textarea.value = editor.getValue();
            });

            textarea.addEventListener('input', function() {
                localStorage.setItem('scriptEditorData', this.value);
                editor.setValue(this.value);
            });

            // Handle reload button
            reloadBtn.addEventListener('click', function() {
                fetch(window.location.href)
                    .then(response => response.text())
                    .then(html => {
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(html, 'text/html');
                        const serverData = doc.querySelector('.script-editor').value;

                        // Update both editor and textarea
                        editor.setValue(serverData);
                        textarea.value = serverData;

                        // Save to localStorage
                        localStorage.setItem('scriptEditorData', serverData);
                    })
                    .catch(error => {
                        console.error('Error reloading data:', error);
                    });
            });

            // Handle form submit to ensure latest content is submitted
            document.querySelector('.script-form').addEventListener('submit', function() {
                if (editorToggle.checked) {
                    textarea.value = editor.getValue();
                }
            });
        });
    </script>
</body>
</html>