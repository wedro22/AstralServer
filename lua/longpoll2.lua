--- Модуль для безопасных Long Poll запросов с обработкой ошибок
-- @module longPoll
local internet = require("internet")
local computer = require("computer")

local longPoll = {}

--- Получает метаданные ответа сервера
-- @local
-- @param handle userdata Объект соединения
-- @return number|nil Код статуса HTTP
-- @return string|nil Сообщение статуса
-- @return table|nil Заголовки ответа
-- @return string|nil Сообщение об ошибке
local function getResponseMetadata(handle)
    if not handle or not handle.response then
        return nil, nil, nil, "invalid handle"
    end

    local ok, code, status, headers = pcall(handle.response)
    if not ok then
        return nil, nil, nil, "response metadata unavailable"
    end

    return code, status, headers
end

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

--- Преобразует таблицу в application/x-www-form-urlencoded
-- @local
-- @param params table Таблица параметров
-- @return string Строка параметров
local function urlEncode(params)
    local result = {}
    for k, v in pairs(params) do
        table.insert(result, string.urlEncode(tostring(k))
        table.insert(result, "=")
        table.insert(result, string.urlEncode(tostring(v)))
        table.insert(result, "&")
    end
    result[#result] = nil -- Удаляем последний &
    return table.concat(result)
end

--- Выполняет Long Poll запрос с таймаутом и обработкой ошибок
-- @param url string URL для запроса
-- @param[opt] data string|table Тело запроса (nil для GET/HEAD)
-- @param[opt] headers table Дополнительные HTTP-заголовки
-- @param[optchain="GET"] method string HTTP-метод
-- @param[opt=60] timeout number Таймаут в секундах
-- @return boolean ok Успешность операции
-- @return any result Данные ответа или текст ошибки
-- @return table|nil headers Заголовки ответа
function longPoll.request(url, data, headers, method, timeout)
    -- Проверка обязательных параметров
    if type(url) ~= "string" or url == "" then
        return false, "invalid URL", nil
    end

    -- Установка значений по умолчанию
    method = method or "GET"
    timeout = timeout or 60
    headers = headers or {}

    -- Подготовка тела запроса
    if type(data) == "table" then
        data = urlEncode(data)
        headers["Content-Type"] = headers["Content-Type"] or "application/x-www-form-urlencoded"
    end

    local deadline = computer.uptime() + timeout
    local handle, err

    -- Безопасное создание соединения
    local ok, result = pcall(function()
        return internet.request(url, data, headers, method)
    end)

    if not ok then
        return false, "request failed: " .. tostring(result), nil
    end

    handle = result

    -- Ожидание соединения с таймаутом
    while computer.uptime() < deadline do
        local code, status, hdrs, err = getResponseMetadata(handle)
        if err then
            handle:close()
            return false, err, nil
        end

        if code then
            -- Чтение данных
            local data, err = readAllData(handle)
            if err then
                handle:close()
                return false, err, hdrs
            end

            handle:close()

            -- Проверка кода статуса
            if code >= 200 and code < 300 then
                return true, data, hdrs
            else
                return false, string.format("%d %s", code, status), hdrs
            end
        end

        computer.pullSignal(0.1) -- Не блокировать надолго
    end

    -- Таймаут
    if handle and handle.close then
        pcall(handle.close)
    end
    return false, "timeout after " .. timeout .. " seconds", nil
end

return longPoll