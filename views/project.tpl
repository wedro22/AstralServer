<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}} - Scripts</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Проект: {{client_name}}/{{project_name}}</h1>
        <a href="/astral/{{client_name}}">← Назад к проектам</a>

        % if defined('error') and error:
            <div class="error">{{error}}</div>
        % end

        <h2>Скрипты:</h2>
        <ul>
            % for script in scripts:
                <li><a href="/astral/{{client_name}}/{{project_name}}/{{script}}">{{script}}</a></li>
            % end
        </ul>

        <form method="POST">
            <label for="script_name">Новый скрипт:</label>
            <input type="text" id="script_name" name="script_name" required>
            <button type="submit">Создать</button>
        </form>
    </div>
</body>
</html>