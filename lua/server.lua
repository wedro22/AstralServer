local internet = require("internet")
--local os = require("os")проверка по времени
local URL="https://wedro22.share.zrok.io/astral"
local handle, reason = internet.request(URL)
if not handle then
    print("Ошибка подключения:", reason)
else
    local response = ""
    for chunk in handle do
        response = response .. chunk
    end
    print("Ответ сервера:", response)

    pcall(handle.close, handle)
end