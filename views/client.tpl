<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}} - Projects</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Клиент: {{client_name}}</h1>
        <a href="/astral">← Назад к списку клиентов</a>

        <form action="/astral/{{client_name}}/action/delete" method="post">
            <button type="submit">Удалить клиента</button>
        </form>

        % if defined('error') and error:
            <div class="error">{{error}}</div>
        % end

        <h2>Проекты:</h2>
        <ul>
            % for project in projects:
                <li><a href="/astral/{{client_name}}/{{project}}">{{project}}</a></li>
            % end
        </ul>

        <form method="POST">
            <label for="project_name">Новый проект:</label>
            <input type="text" id="project_name" name="project_name" required>
            <button type="submit">Создать</button>
        </form>
    </div>
</body>
</html>