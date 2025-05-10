<!DOCTYPE html>
<html>
<head>
    <title>{{client_name}}/{{project_name}}/{{script_name}}</title>
    <link rel="stylesheet" href="/static/style.css">
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
            <textarea name="script_data" class="script-editor">{{script_data}}</textarea>
            <div class="form-actions">
                <button type="submit" name="save" class="primary-btn">Сохранить</button>
                <button type="submit" name="reload" class="secondary-btn">Перезагрузить</button>
            </div>
        </form>
    </div>
</body>
</html>