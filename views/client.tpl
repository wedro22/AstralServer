<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}} - Projects</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Клиент: {{client_name}}</h1>

        <div class="header-actions">
            <a href="/astral" class="back-link">← Назад к выбору клиента</a>

            <div class="delete-container">
                <a href="#" class="delete-link">Удалить клиент</a>
                <form action="/astral/{{client_name}}/action/delete" method="post" class="delete-confirm">
                    <span>Вы уверены?</span>
                    <button type="submit" class="confirm-btn">Да</button>
                    <a href="#" class="cancel-btn">Нет</a>
                </form>
            </div>
        </div>

        % if defined('error') and error:
            <div class="error">{{error}}</div>
        % end

        <h2>Проекты:</h2>
        % if projects:
            <ul class="project-list">
                % for project in projects:
                    <li>
                        <a href="/astral/{{client_name}}/{{project['name']}}">{{project['name']}}</a>
                        % if project['type']:
                            <span class="project-type">({{project['type']}})</span>
                        % end
                    </li>
                % end
            </ul>
        % else:
            <p>Нет проектов</p>
        % end

        <form method="POST" class="project-form">
            <label for="project_name">Новый проект:</label>

            <div class="fields-container">
                <input type="text" id="project_name" name="project_name" placeholder="имя проекта" required class="name-field">
                <input type="text" id="project_type" name="project_type" placeholder="тип" class="type-field">
                <button type="submit">Создать</button>
            </div>
        </form>
    </div>
</body>
</html>