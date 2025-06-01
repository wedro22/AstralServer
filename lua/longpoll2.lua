--- Модуль для безопасных Long Poll запросов с обработкой ошибок
-- @module longPoll
local internet = require("internet")
local computer = require("computer")

local longPoll = {}
--- Выполняет Long Poll запрос с таймаутом и обработкой ошибок
-- @param url string URL для запроса
-- @param[opt] data string|table Тело запроса (nil для GET/HEAD)
-- @param[opt] headers table Дополнительные HTTP-заголовки
-- @param[optchain="GET"] method string HTTP-метод
-- @param[opt=30] timeout number Таймаут в секундах
-- @return text|nil result текст результата запроса страницы
-- @return table|nil headers таблица хэдеров результата запроса страницы
-- @return text|nil err текст ошибки или nil при безошибочном выполнении
function longPoll.request(url, data, headers, method, timeout)
    -- Проверка обязательных параметров
    if type(url) ~= "string" or url == "" then
        return nil, nil, "URL is incorrect"
    end
    timeout = timeout or 30     -- 30 сек
    local free_memory_size = 8 * 1024    -- 8 KB памяти не трогаем
    local read_data=""
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
        pcall(handle.close, handle)
        return nil, nil, "Error: request failed, handle: " .. tostring(handle)
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
        if err ~= "" then err = err .. "\n" end
        err = err .. "Error: handler is not defined, code, status: ".. code .. " " .. status
    end

    -- Чтение данных (упрощённое?)
    --computer.pullSignal(0.1) -- Не блокировать надолго
    --for chunk in handle do
        --проверка памяти
    --    if computer.freeMemory() < free_memory_size then
    --        if err ~= "" then err = err .. "\n" end
    --        err = err .. "Error: low memory: " .. tostring(computer.freeMemory()//1024) .. " KB)"
    --        break
    --    end
    --    read_data = read_data .. chunk
    --end

    local ok, chunk, e
    while computer.uptime() < deadline do
        computer.pullSignal(0.1) -- Не блокировать надолго
        ok, chunk, reason = pcall(handle.read)
        --if not ok then
        if chunk then
            read_data = read_data .. chunk
        elseif reason then --and reason ~= "timeout"
            if err ~= "" then err = err .. "\n" end
            err = err .. "Error: Server disconnected connection or error, reason: " .. tostring(reason)
            break -- Сервер закрыл соединение или ошибка
        elseif not chunk and ok then
            break   --ok
        end
    end

    --проверка таймаута
    if computer.uptime() >= deadline then
        if err ~= "" then err = err .. "\n" end
        err = err .. "Error: timeout"
    end


    -- Преобразование пустой строки ошибок в nil для вывода
    if err == "" then
        err = nil
    end

    --окончание программы
    pcall(handle.close, handle)
    return read_data, headers, err
end

return longPoll