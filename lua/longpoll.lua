-- Модуль для Long Poll запросов с обработкой ошибок
local internet = require("internet")
local computer = require("computer")

local longPoll = {}

-- Функция для выполнения Long Poll запроса с таймаутом и обработкой ошибок
function longPoll.request(url, timeout, headers)
    headers = headers or {["Connection"] = "keep-alive"} -- Можно добавить свои заголовки
    timeout = timeout or 30 -- Таймаут по умолчанию: 30 секунд

    local ok, request = pcall(internet.request, url, nil, headers)
    if not ok then
        return nil, "Ошибка создания запроса: " .. tostring(request)
    end

    local response = ""
    local deadline = computer.uptime() + timeout

    while computer.uptime() < deadline do
        local chunk, reason
        ok, chunk, reason = pcall(request.read)

        if not ok then
            return nil, "Ошибка чтения данных: " .. tostring(chunk)
        end

        if chunk then
            response = response .. chunk
        elseif reason ~= "timeout" then
            break -- Сервер закрыл соединение или ошибка
        end

        computer.pullSignal(0.1) -- Ожидание без нагрузки на CPU
    end

    if response == "" then
        return nil, "Нет данных (таймаут или сервер не ответил)"
    end

    return response
end

return longPoll