local longPoll = require("longpoll") -- Путь зависит от места сохранения

local url = "https://relay.tunnelhead.dev/t/demo/poll"
local timeout = 60 -- 60 секунд

local response, err = longPoll.request(url, timeout)

if err then
    print("Ошибка:", err)
else
    print("Успешный ответ:", response)
end