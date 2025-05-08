<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Скрипт: {{client_name}}/{{project_name}}/{{script_name}}</h1>
        <a href="/astral/{{client_name}}/{{project_name}}">← Назад к скриптам</a>

        <form action="/astral/{{client_name}}/{{project_name}}/{{script_name}}/action/delete" method="post">
            <button type="submit">Удалить скрипт</button>
        </form>

        % if defined('message') and message:
            <div class="message">{{message}}</div>
        % end

        <form method="POST">
            <textarea name="script_data" rows="20" cols="80">{{script_data}}</textarea>
            <div class="buttons">
                <button type="submit" name="save">Сохранить</button>
                <button type="submit" name="reload">Перезагрузить</button>
            </div>
        </form>
    </div>
</body>
</html>