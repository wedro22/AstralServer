local internet = require("internet")
local os = require("os")

local URLGET = "https://wedro.share.zrok.io/astral/gt/gt/get/raw"
local URLPOST = "https://wedro.share.zrok.io/astral/gt/gt/post/raw"
local running = true

-- Функция для безопасного GET-запроса
-- return nil or response
local function safeGet(url)
    local handle, reason = internet.request(url)
    if not handle then
        return nil
    end

    local success, response = pcall(function()
        local result = ""
        for chunk in handle do
            result = result .. chunk
        end
        return result
    end)

    pcall(handle.close, handle)

    if not success then
        return nil
    end

    return response
end

-- Функция для безопасного POST-запроса
-- return nil or response
local function safePost(url, data)
    local handle, reason = internet.request(url, data)

    if not handle then
        return nil
    end

    local success, response = pcall(function()
        local result = ""
        for chunk in handle do
            result = result .. chunk
        end
        return result
    end)

    pcall(handle.close, handle)

    if not success then
        return nil
    end

    return response
end

while running do
    local time = os.date("%H:%M:%S")
    print("server echo " .. time)

    -- Получаем данные с сервера
    local response = safeGet(URLGET)
    print(tostring(response))

    -- Отправляем ответ сервера обратно
    local postResponse = safePost(URLPOST, tostring(response))
    print(tostring(postResponse))

    os.sleep(10)
end