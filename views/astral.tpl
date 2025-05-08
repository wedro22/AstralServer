<!DOCTYPE html>
<html>
<head>
    <title>Astral - Вход</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Astral Project Manager</h1>

        % if defined('error') and error:
            <div class="error">{{error}}</div>
        % end

        <form method="POST" action="/astral">
            <label for="client_name">Введите имя клиента:</label>
            <input type="text" id="client_name" name="client_name" required autofocus>
            <button type="submit">OK</button>
        </form>
    </div>
</body>
</html>