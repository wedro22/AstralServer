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


    -- Работа с хандлером
    -- Корутина для получения заголовков
    local coHeaders = coroutine.create(function()
        while computer.uptime() < deadline do
            --https://computercraft.ru/blogs/entry/667-kak-vsyo-taki-ispolzovat-internet-platu/
            local ok, c, s, h = pcall(handle.response)
            if h then
                code, status, headers = c, s, h
                break
            end
            coroutine.yield()  -- Отдаём управление
        end
    end)
    -- Корутина для чтения данных
    local coData = coroutine.create(function()
        while computer.uptime() < deadline do
            local ok, chunk, reason = pcall(handle.read)
            if chunk then
                read_data = read_data .. chunk
            elseif reason then --and reason ~= "timeout"
                if err ~= "" then err = err .. "\n" end
                err = err .. "Error: Server disconnected connection or error, reason: " .. tostring(reason)
                break -- Сервер закрыл соединение или ошибка
            elseif not chunk and ok then
                break  -- Успешное завершение
            end
        end
        coroutine.yield()  -- Отдаём управление
    end)

    computer.pullSignal(0.1)-- Время для инициализации хандлера
    -- Запускаем обе корутины
    coroutine.resume(coHeaders)
    coroutine.resume(coData)

    -- Ждём, пока обе корутины завершатся или истечёт таймаут
    while (coroutine.status(coHeaders) ~= "dead" or coroutine.status(coData) ~= "dead")
      and computer.uptime() < deadline do
    -- Возобновляем обе корутины на каждой итерации
    if coroutine.status(coHeaders) == "suspended" then
        coroutine.resume(coHeaders)
    end
    if coroutine.status(coData) == "suspended" then
        coroutine.resume(coData)
    end

    computer.pullSignal(0.1)
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