local internet = require("internet")
local component = require("component")
local gpu = component.gpu
local os = require("os")

local URLGET = "https://wedro.share.zrok.io/astral/gt/gt/get/raw"
local URLPOST = "https://wedro.share.zrok.io/astral/gt/gt/post/raw"

-- Функция для безопасного GET-запроса
local function safeGet(url)
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

    pcall(handle.close, handle)

    if not success then
        return nil, "Ошибка чтения данных: " .. tostring(response)
    end

    return response
end

-- Функция для безопасного POST-запроса
local function safePost(url, data)
    local handle, reason = internet.request(url, data, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #data
    })

    if not handle then
        return false, "Ошибка подключения: " .. tostring(reason)
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
        return false, "Ошибка отправки данных: " .. tostring(response)
    end

    return true, response
end

-- Получаем текущее разрешение экрана
local width, height = gpu.getResolution()

-- Основной цикл программы
while true do
    -- Выводим текущее время
    local time = os.date("%H:%M:%S")
    print(time)

    -- Получаем данные с сервера
    local response, err = safeGet(URLGET)
    if err then
        print("Ошибка получения данных:", err)
    else
        -- Выводим ответ сервера
        print(response)

        -- Отправляем ответ сервера обратно
        local postSuccess, postResponse = safePost(URLPOST, response or "")
        if postSuccess then
            print("Ответ: " .. tostring(postResponse))
        else
            print("Ответ: false")
            if postResponse then
                print("Детали ошибки: " .. postResponse)
            end
        end
    end

    -- Ждем 10 секунд перед следующим обновлением
    os.sleep(10)
end