local internet = require("internet")
local os = require("os")
local executor = require("Astral/executor4")
local computer = require("computer")
local longPoll = require("Astral/longpoll3")

-- Конфигурация
local CONFIG = {
    GET_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/get/raw",
    POST_URL = "https://wedro22.pythonanywhere.com/astral/gt/gt/post/raw",
    POLL_INTERVAL = 0.05, -- тик
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
    local h = ""
    local p,r,e
    if err then
        print(err)
    end
    if result then
        print("Executing code...")
        p,r,e = executor.safeExecute(result)
        if headers then
            for i,v in pairs(headers) do
                for ii,vv in pairs(v) do
                    h=h..tostring(i).." "..tostring(ii).." "..tostring(vv).."\n"
                end
            end
        end
    end
    result, headers, err = longPoll.request(CONFIG.POST_URL, "[P] Prints:\n"..p.."\n[R] Returns:\n"..r.."\n[E] Errors:\n"..e.."\n[H] Headers:\n"..h)
    if not err then
        print("Result sent")
    else
        print("Result sent, err: ".. err)
    end

    print("Memory: " .. checkMemory())
    os.sleep(CONFIG.POLL_INTERVAL)
end