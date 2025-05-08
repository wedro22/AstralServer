<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}} - Scripts</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Проект: {{client_name}}/{{project_name}}</h1>

        <div class="header-actions">
            <a href="/astral/{{client_name}}" class="back-link">← Назад к списку проектов</a>

            <div class="delete-container">
                <a href="#" class="delete-link">Удалить проект</a>
                <form action="/astral/{{client_name}}/{{project_name}}/action/delete" method="post" class="delete-confirm">
                    <span>Вы уверены?</span>
                    <button type="submit" class="confirm-btn">Да</button>
                    <a href="#" class="cancel-btn">Нет</a>
                </form>
            </div>
        </div>

        % if error:
            <div class="error">{{error}}</div>
        % end

        <h2>Скрипты:</h2>
        % if scripts:
            <ul class="items-list">
                % for script in scripts:
                    <li><a href="/astral/{{client_name}}/{{project_name}}/{{script}}">{{script}}</a></li>
                % end
            </ul>
        % else:
            <p class="no-items">Нет скриптов</p>
        % end

        <form method="POST" class="creation-form">
            <label for="script_name">Новый скрипт:</label>
            <input type="text" id="script_name" name="script_name" required>
            <button type="submit">Создать</button>
        </form>
    </div>
</body>
</html>