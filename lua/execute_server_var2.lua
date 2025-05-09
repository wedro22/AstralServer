-- Серверный скрипт для OpenComputers в GregTech
-- Запрашивает код с удаленного сервера, выполняет его безопасно и возвращает результат

local component = require("component")
local internet = require("internet")
local event = require("event")
local serialization = require("serialization")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro.share.zrok.io/astral/gt/gt/get/raw",
    POST_URL = "https://wedro.share.zrok.io/astral/gt/gt/post/raw",
    POLL_INTERVAL = 10, -- секунд
    MAX_OUTPUT_LENGTH = 1024 * 1024 -- максимальная длина вывода (1MB)
}

-- Локальные переменные
local running = true
local lastError = nil

-- Безопасная загрузка и выполнение кода
local function safeLoad(code)
    local chunk, err = load(code, "remote_code", "t", setmetatable({}, {__index = _G}))
    if not chunk then
        return nil, "Ошибка загрузки: " .. tostring(err)
    end

    -- Перехватываем вывод print
    local output = {}
    local oldPrint = print
    print = function(...)
        local args = {...}
        for i = 1, select('#', ...) do
            args[i] = tostring(args[i])
        end
        table.insert(output, table.concat(args, "\t"))
        oldPrint(...)
    end

    -- Выполняем код с защитой
    local results = {xpcall(chunk, function(err)
        return debug.traceback(tostring(err), 2)
    end)}

    -- Восстанавливаем оригинальный print
    print = oldPrint

    local success = table.remove(results, 1)

    if not success then
        return nil, table.remove(results, 1), output
    end

    return results, nil, output
end

-- Отправка запроса на сервер
local function httpRequest(url, data)
    local request = internet.request(url, data and tostring(data) or nil)
    local response = ""

    for chunk in request do
        response = response .. chunk
        if #response > CONFIG.MAX_OUTPUT_LENGTH then
            return nil, "Превышен максимальный размер ответа"
        end
    end

    return response
end

-- Основной цикл обработки
local function process()
    while running do
        local code, err
        local success, response = pcall(httpRequest, CONFIG.GET_URL)

        if not success then
            err = "Ошибка запроса: " .. tostring(response)
        elseif not response then
            err = "Пустой ответ от сервера"
        else
            code = response
        end

        local results, execErr, output
        if code then
            results, execErr, output = safeLoad(code)
        end

        -- Формируем ответ
        local responseData = {
            success = not (err or execErr),
            error = err or execErr,
            output = output or {},
            results = results or {}
        }

        -- Отправляем результат обратно
        if not err then
            local postSuccess, postErr = pcall(httpRequest, CONFIG.POST_URL, serialization.serialize(responseData))
            if not postSuccess then
                lastError = "Ошибка отправки результата: " .. tostring(postErr)
            end
        else
            lastError = err
        end

        -- Ждем перед следующим запросом
        local _, interrupt = event.pull(CONFIG.POLL_INTERVAL, "interrupt")
        if interrupt then
            running = false
        end
    end
end

-- Обработка прерывания
local function handleInterrupt()
    print("Сервер остановлен")
    running = false
end

-- Запуск сервера
print("Сервер запущен. Нажмите Ctrl+Alt+C для остановки.")
event.listen("interrupt", handleInterrupt)

local ok, err = pcall(process)
if not ok then
    print("Критическая ошибка: " .. tostring(err))
end

event.ignore("interrupt", handleInterrupt)
print("Сервер остановлен.")