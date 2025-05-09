local internet = require("internet")
--local os = require("os")проверка по времени реализовать потом
local URL="https://wedro.share.zrok.io/astral/gt/gt"
local URLGET="https://wedro.share.zrok.io/astral/gt/gt/get/raw"
local URLPOST="https://wedro.share.zrok.io/astral/gt/gt/post/raw"
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