local internet = require("internet")
--local os = require("os") проверка по времени реализовать потом
local URL = "https://wedro.share.zrok.io/astral/gt/gt"
local URLGET = "https://wedro.share.zrok.io/astral/gt/gt/get/raw"
local URLPOST = "https://wedro.share.zrok.io/astral/gt/gt/post/raw"

local function safeRequest(url)
    local handle, reason = internet.request(url)
    if not handle then
        return nil, "Ошибка подключения: " .. tostring(reason)
    end

    local success, response = pcall(function()
        local result = ""
        for chunk in handle do
            result = result .. chunk
        end
        return result
    end)

    -- Закрываем handle в любом случае
    pcall(handle.close, handle)

    if not success then
        return nil, "Ошибка чтения данных: " .. tostring(response)
    end

    return response
end

-- Основная логика
local response, err = safeRequest(URLGET)
if err then
    print("Произошла ошибка:", err)
else
    print("Ответ сервера:", response)
end

-- Программа продолжает работу после этого
print("Программа продолжает выполнение...")