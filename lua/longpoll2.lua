--- Модуль для безопасных Long Poll запросов с обработкой ошибок
-- @module longPoll
local internet = require("internet")
local computer = require("computer")

local longPoll = {}

--- Читает все данные из ответа
-- @local
-- @param handle userdata Объект соединения
-- @return string|nil Данные
-- @return string|nil Ошибка
local function readAllData(handle)
    if not handle then
        return nil, "invalid handle"
    end

    local data = ""
    local ok, chunk = pcall(handle.read)
    while ok and chunk do
        data = data .. chunk
        ok, chunk = pcall(handle.read)
    end

    if not ok then
        return nil, "read error: " .. tostring(chunk)
    end

    return data
end

--- Выполняет Long Poll запрос с таймаутом и обработкой ошибок
-- @param url string URL для запроса
-- @param[opt] data string|table Тело запроса (nil для GET/HEAD)
-- @param[opt] headers table Дополнительные HTTP-заголовки
-- @param[optchain="GET"] method string HTTP-метод
-- @param[opt=60] timeout number Таймаут в секундах
-- @return boolean ok Успешность операции
-- @return text result текст ответа или текст ошибки
-- @return table|nil headers Заголовки ответа
function longPoll.request(url, data, headers, method, timeout)
    -- Проверка обязательных параметров
    if type(url) ~= "string" or url == "" then
        return false, "invalid URL", nil
    end

    -- Безопасное создание соединения
    local ok, handle = pcall(function()
        return internet.request(url, data, headers, method)
    end)
    if not ok or not handle then
        return false, "request failed, handle:\n" .. tostring(handle), nil
    end

    -- Соединение прошло успешно
    timeout = timeout or 60
    local deadline = computer.uptime() + timeout
    local data = ""

    -- Ожидание соединения с таймаутом
    while computer.uptime() < deadline do
        --[[Получение метаданных
            Если соединение ещё не установлено, вернёт nil.
            Если возникла ошибка, вернёт nil и сообщение об ошибке. Например, nil, "connection lost".
            В противном случае возвращает 3 значения:
                Код ответа (например, 200).
                Статус (например, "OK").
                Таблицу с хедерами, которые отправил сервер. Выглядит примерно так:
                {["Content-Type"] = {"application/json", n = 1}, ["X-My-Header"] = {"value 1", "value 2", n = 2}}.
        --]]
        local ok, code, status, headers = pcall(handle.response)
        if not headers then
            pcall(handle:close())
            return false, "handle response metadata error, status:\n" .. tostring(status), nil
        end

        -- Чтение данных
        local ok, chunk = pcall(handle.read)
        while ok and chunk do
            data = data .. chunk
            ok, chunk = pcall(handle.read)
        end

        if not ok then
            pcall(handle.close)
            return false, "read error, chunk:\n" .. tostring(chunk), headers
        end

        pcall(handle.close)

        -- Проверка кода статуса
        if code >= 200 and code < 300 then
            return true, data, headers
        else
            return false, string.format("%d %s", code, status), headers
        end

        computer.pullSignal(0.1) -- Не блокировать надолго
    end

    -- Таймаут
    pcall(handle.close)
    return false, "timeout after " .. timeout .. " seconds", nil
end

return longPoll