--- Модуль для безопасных Long Poll запросов с обработкой ошибок
-- @module longPoll
local internet = require("internet")
local computer = require("computer")

local longPoll = {}

    local function safe_handle_reader(handle)
        chunk_size = 16 * 1024    -- 16 KB на чанк
        local data = ""

        while true do
            local ok, chunk = pcall(handle.read, chunk_size)

            -- Проверка на ошибку чтения
            if not ok then
                return false, data, "Error reading: " .. tostring(chunk)
            end

            -- Проверка на конец файла
            if not chunk or #chunk == 0 then
                break
            end

            -- Проверка на превышение памяти
            if computer.freeMemory() < chunk_size then
                return false, data, "Error: low memory: " .. computer.freeMemory()//1024 .. " KB)"
            end

            data = data .. chunk
        end

        return true, data, ""
    end

--- Выполняет Long Poll запрос с таймаутом и обработкой ошибок
-- @param url string URL для запроса
-- @param[opt] data string|table Тело запроса (nil для GET/HEAD)
-- @param[opt] headers table Дополнительные HTTP-заголовки
-- @param[optchain="GET"] method string HTTP-метод
-- @param[opt=60] timeout number Таймаут в секундах
-- @return text|nil result текст результата запроса страницы
-- @return table|nil headers таблица хэдеров результата запроса страницы
-- @return text|nil err текст ошибки или nil при безошибочном выполнении
function longPoll.request(url, data, headers, method, timeout)
    -- Проверка обязательных параметров
    if type(url) ~= "string" or url == "" then
        return nil, nil, "URL is incorrect"
    end
    timeout = timeout or 60     -- 60 сек
    local deadline = computer.uptime() + timeout
    local code, status, headers
    local handle
    local err = ""

    -- Попытка получения соединения и хандлера
    while computer.uptime() < deadline do
        _, handle = pcall(function()
            return internet.request(url, data, headers, method)
        end)
        if handle then
            break
        end
        computer.pullSignal(0.1) -- Не блокировать надолго
    end
    -- Попытка соединения провалилась
    if not handle then
        pcall(handle.close)
        return nil, nil, "Error: request failed. handle: " .. tostring(handle)
    end
    -- Соединение прошло успешно

    -- Работа с хандлером: Попытка получения хэдеров
    while computer.uptime() < deadline do
        computer.pullSignal(0.1) -- Не блокировать надолго
        --https://computercraft.ru/blogs/entry/667-kak-vsyo-taki-ispolzovat-internet-platu/
        _, code, status, headers = pcall(handle.response)
        if headers then
            break
        end
    end
    if not headers then
        err = err .. "Error: handler is not defined. code, status: ".. code .. " " .. status
    end

    -- Чтение данных
    computer.pullSignal(0.1) -- Не блокировать надолго
    local ok, read_data, e = safe_handle_reader(handle)
    if not ok then
        if err ~= "" then
            err = err .. "\n"
        end
        err = err .. e
    end
    if err == "" then
        err = nil
    end

    --окончание программы
    pcall(handle.close)
    return read_data, headers, err
end

return longPoll