-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro.share.zrok.io/astral/gt/gt/get/raw",
    POST_URL = "https://wedro.share.zrok.io/astral/gt/gt/post/raw",
    POLL_INTERVAL = 10, -- секунд
    MAX_OUTPUT_LENGTH = 1024 * 1024 -- 1MB
}

-- Инициализация компонентов
local internet = require("internet")
local component = require("component")
local computer = require("computer")

-- Безопасный запрос с обработкой ошибок
local function safeRequest(url, method, data)
    local ok, result = pcall(function()
        local handle = internet.request(url, data, {method = method})
        local response = ""
        for chunk in handle do
            if #response + #chunk <= CONFIG.MAX_OUTPUT_LENGTH then
                response = response .. chunk
            else
                break
            end
        end
        return response
    end)
    return ok and result or "ERROR: " .. tostring(result)
end

-- Безопасное выполнение кода с перехватом вывода
local function safeExecute(code)
    local output = {}
    local oldPrint = print
    print = function(...)
        local args = {...}
        for i = 1, select('#', ...) do
            args[i] = tostring(args[i])
        end
        table.insert(output, table.concat(args, "\t"))
    end

    local result = {pcall(load(code, "=client", "t", _G))}
    print = oldPrint

    if not result[1] then
        table.insert(output, "EXECUTION ERROR: " .. tostring(result[2]))
    elseif result[2] ~= nil then
        table.insert(output, "RETURN: " .. tostring(result[2]))
    end

    return table.concat(output, "\n")
end

-- Основной цикл
while true do
    local code = safeRequest(CONFIG.GET_URL, "GET")

    if code and code ~= "" and not code:find("^ERROR:") then
        local output = safeExecute(code)
        safeRequest(CONFIG.POST_URL, "POST", output)
    end

    os.sleep(CONFIG.POLL_INTERVAL)
end