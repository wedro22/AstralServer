local internet = require("internet")
local os = require("os")
local executor = require("executor4") --не тестил, сейчас работает 2
local computer = require("computer")
local longPoll = require("longpoll2")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/get/raw",
    POST_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/post/raw",
    GET_URL2 = "https://relay.tunnelhead.dev/t/demo/poll",
    POLL_INTERVAL = 0.2, -- секунд
}

local function checkMemory()
    return tostring(math.floor(computer.freeMemory() / computer.totalMemory() * 100)) .. "%"
end

-- Основной цикл сервера
while true do
    local time = os.date("%H:%M:%S")
    print("Server running at " .. time)

    -- Получаем код для выполнения
    local result, headers, err = longPoll.request(CONFIG.GET_URL2)
    if not err then
        print("Executing code...")
        local p,r,e = executor.safeExecute(result)
        local h = ""
        for i,v in pairs(headers) do
        for ii,vv in pairs(v) do
            h=h..tostring(i).." "..tostring(ii).." "..tostring(vv).." "
        end
    end
        longPoll.request(CONFIG.POST_URL, "[P] Prints:\n"..p.."\n[R] Returns:\n"..r.."\n[E] Errors:\n"..e.."\n[H] Headers:\n"..)
        print("Execution completed, result sent")
    else
        print(err)
    end
        print("Memory: " .. checkMemory())

    os.sleep(CONFIG.POLL_INTERVAL)
end