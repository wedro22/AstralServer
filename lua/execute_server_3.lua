local internet = require("internet")
local os = require("os")
local executor = require("executor2")
local computer = require("computer")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/get/raw",
    POST_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/post/raw",
    POLL_INTERVAL = 5, -- секунд
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

local function checkMemory()
    return tostring(math.floor(computer.freeMemory() / computer.totalMemory() * 100)) .. "%"
end

-- Основной цикл сервера
while true do
    local time = os.date("%H:%M:%S")
    print("Server running at " .. time)

    -- Получаем код для выполнения
    local code = safeHttpRequest(CONFIG.GET_URL)
    if code and code ~= "" then
        print("Executing code...")
        local p,r,e = executor.safeExecute(code)
        safeHttpRequest(CONFIG.POST_URL, "[P] Prints:\n"..p.."\n[R] Returns:\n"..r.."\n[E] Errors:\n"..e)
        print("Execution completed, result sent")
    else
        print("No code received or empty response")
    end
        print("Memory: " .. checkMemory())

    os.sleep(CONFIG.POLL_INTERVAL)
end