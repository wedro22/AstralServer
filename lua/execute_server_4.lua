local internet = require("internet")
local os = require("os")
local executor = require("executor4") --не тестил, сейчас работает 2
local computer = require("computer")
local longPoll = require("longpoll2")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/get/raw",
    POST_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/post/raw",
    POLL_INTERVAL = 5, -- секунд
    MAX_OUTPUT_LENGTH = 1024 * 1024 -- максимальная длина вывода (1MB)
}

local function checkMemory()
    return tostring(math.floor(computer.freeMemory() / computer.totalMemory() * 100)) .. "%"
end

-- Основной цикл сервера
while true do
    local time = os.date("%H:%M:%S")
    print("Server running at " .. time)

    -- Получаем код для выполнения
    local result, headers, err = longPoll.request(CONFIG.GET_URL)
    if not err then
        print("Executing code...")
        local p,r,e = executor.safeExecute(result)
        longPoll.request(CONFIG.POST_URL, "[P] Prints:\n"..p.."\n[R] Returns:\n"..r.."\n[E] Errors:\n"..e)
        print("Execution completed, result sent")
    else
        print(err)
    end
        print("Memory: " .. checkMemory())

    os.sleep(CONFIG.POLL_INTERVAL)
end