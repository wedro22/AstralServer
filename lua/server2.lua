local internet = require("internet")
local os = require("os")
local computer = require("computer")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/get/raw",
    POST_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/post/raw",
    POLL_INTERVAL = 5, -- секунд
    MAX_OUTPUT_LENGTH = 1024 * 1024, -- максимальная длина вывода (1MB)
    MEMORY_THRESHOLD = 0.2 -- минимальная доля свободной памяти (20%)
}

-- Проверка свободной памяти
local function checkMemory()
    return computer.freeMemory() / computer.totalMemory() > CONFIG.MEMORY_THRESHOLD
end

-- Безопасный HTTP-запрос с ограничением памяти
local function safeHttpRequest(url, data)
    if not checkMemory() then return nil, "low memory" end

    local handle, response
    local success, err = pcall(function()
        handle = data and internet.request(url, data, nil, 10) or internet.request(url, nil, nil, 10)
        if not handle then return nil end

        response = ""
        for chunk in handle do
            if not checkMemory() or #response + #chunk > CONFIG.MAX_OUTPUT_LENGTH then
                response = response .. "\n...OUTPUT TRUNCATED..."
                break
            end
            response = response .. chunk
            os.sleep(0) -- даем время другим процессам
        end
        return response
    end)

    pcall(handle and handle.close, handle)
    return success and response or nil, err
end

-- Безопасное выполнение кода с таймаутом
local function safeExecute(code)
    if not checkMemory() then return "", "low memory" end

    local output = {}
    local env = setmetatable({
        print = function(...)
            if not checkMemory() then return end
            local args = {...}
            for i = 1, select('#', ...) do
                args[i] = tostring(args[i])
            end
            table.insert(output, table.concat(args, "\t"))
            if #output > 100 then -- ограничиваем количество строк вывода
                table.remove(output, 1)
            end
        end
    }, {__index = _G})

    local start_time = computer.uptime()
    local max_time = 30 -- максимальное время выполнения (секунд)

    -- Добавляем проверку времени выполнения в окружение
    env._checkTimeout = function()
        if computer.uptime() - start_time > max_time then
            error("Execution timeout")
        end
    end

    -- Добавляем проверку в код
    code = "local _checkTimeout=_ENV._checkTimeout\n" .. code
    code = code:gsub("([^\n]*)\n", "%1 _checkTimeout()\n")

    local fn, err = load(code, "remote_code", "t", env)
    if not fn then
        return table.concat(output, "\n"), "COMPILE ERROR: " .. err
    end

    local results = {xpcall(fn, debug.traceback)}
    if not results[1] then
        table.insert(output, "RUNTIME ERROR: " .. tostring(results[2]))
    else
        local ret = {}
        for i = 2, #results do
            table.insert(ret, tostring(results[i]))
        end
        if #ret > 0 then
            table.insert(output, "RETURN: " .. table.concat(ret, ", "))
        end
    end

    return table.concat(output, "\n")
end

-- Основной цикл сервера с защитой
while true do
    local time = os.date("%H:%M:%S")
    print("Server running at " .. time)
    computer.beep(1000, 0.1) -- звуковой сигнал для мониторинга

    -- Проверка памяти перед выполнением
    if not checkMemory() then
        print("WARNING: Low memory, skipping cycle")
        os.sleep(CONFIG.POLL_INTERVAL * 2) -- увеличенный интервал при нехватке памяти
        computer.shutdown(true) -- мягкая перезагрузка
    end

    -- Получаем код для выполнения
    local code, err = safeHttpRequest(CONFIG.GET_URL)
    if code and code ~= "" then
        print("Executing code...")
        local result, exec_err = safeExecute(code)
        if exec_err then
            result = (result or "") .. "\n" .. exec_err
        end
        safeHttpRequest(CONFIG.POST_URL, result)
        print("Execution completed, result sent")
    else
        print("No code received or empty response: " .. tostring(err))
    end

    -- Принудительная сборка мусора
    collectgarbage()
    os.sleep(CONFIG.POLL_INTERVAL)
end