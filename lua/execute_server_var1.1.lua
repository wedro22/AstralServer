local internet = require("internet")
local os = require("os")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro.share.zrok.io/astral/gt/gt/get/raw",
    POST_URL = "https://wedro.share.zrok.io/astral/gt/gt/post/raw",
    POLL_INTERVAL = 10, -- секунд
    MAX_OUTPUT_LENGTH = 1024 * 1024 -- максимальная длина вывода (1MB)
}

-- Безопасный HTTP-запрос
local function safeHttpRequest(url, data)
    local handle, result, response
    local success, err = pcall(function()
        handle = data and internet.request(url, data) or internet.request(url)
        if not handle then return nil end

        response = ""
        for chunk in handle do
            if #response + #chunk > CONFIG.MAX_OUTPUT_LENGTH then
                response = response .. "\n...OUTPUT TRUNCATED..."
                break
            end
            response = response .. chunk
        end
        return response
    end)

    pcall(handle and handle.close, handle)
    return success and response or nil
end

-- Безопасное выполнение кода с перехватом всего вывода
local function safeExecute(code)
    local output = {}
    local env = setmetatable({
        print = function(...)
            local args = {...}
            for i = 1, select('#', ...) do
                args[i] = tostring(args[i])
            end
            table.insert(output, table.concat(args, "\t"))
        end
    }, {__index = _G})

    local fn, err = load(code, "remote_code", "t", env)
    if not fn then
        return table.concat(output, "\n"), "COMPILE ERROR: " .. err
    end

    local results = {pcall(fn)}
    if not results[1] then
        table.insert(output, "RUNTIME ERROR: " .. tostring(results[2]))
    else
        -- Добавляем возвращаемые значения (пропуская первый успешный результат)
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

-- Основной цикл сервера
while true do
    local time = os.date("%H:%M:%S")
    print("Server running at " .. time)

    -- Получаем код для выполнения
    local code = safeHttpRequest(CONFIG.GET_URL)
    if code and code ~= "" then
        print("Executing code...")
        local result = safeExecute(code)
        safeHttpRequest(CONFIG.POST_URL, result)
        print("Execution completed, result sent")
    else
        print("No code received or empty response")
    end

    os.sleep(CONFIG.POLL_INTERVAL)
end