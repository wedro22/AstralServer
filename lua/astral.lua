-- Astral Installer for OpenComputers in GregTech New Horizons
-- Загружает последний релиз и устанавливает файлы в папку astral

local component = require("component")
local internet = require("internet")
local fs = require("filesystem")
local computer = require("computer")
local shell = require("shell")
local event = require("event")

-- Директория установки файлов
local astralPath = fs.concat(shell.getWorkingDirectory(), "Astral")
-- Базовый URL репозитория
local repoUrl = "https://raw.githubusercontent.com/wedro22/AstralServer/master/lua/"

-- Получаем имя текущего файла
local currentFileName = "astral"

-- Функция для вывода справки
local function help()
    print("Эта программа нужна для выполнения кода, который размещён удалённо.")
    print("Использование: " .. currentFileName .. " [аргумент]")
    print("Аргументы:")
    print("install - установить необходимые файлы")
    print("run - запустить с установленными настройками")
    print("set - переопределить установленные настройки")
end

-- Функция для вывода прогресса в одну строку
local function printProgress(msg)
    io.write(msg .. " ")
end

-- Функция установки
local function install()
    printProgress("[Начало установки...")

    -- Загрузка release.lua
    printProgress("Загрузка последнего релиза...")
    local releaseUrl = repoUrl .. "release.lua"
    local releaseContent = ""

    -- Пытаемся загрузить release.lua
    local success, err = pcall(function()
        local handle = internet.request(releaseUrl)
        computer.pullSignal(0.2)
        for chunk in handle do
            releaseContent = releaseContent .. chunk
        end
        if handle then pcall(handle.close, handle) end
    end)

    if not success then
        printProgress("Ошибка: (Не удалось загрузить release.lua: " .. err .. ")]")
        return false
    end

    -- Разбираем список файлов
    local fileList = {}
    for line in releaseContent:gmatch("([^\r\n]+)") do
        local cleanedLine = line:gsub("%s+", ""):gsub("^%W+", ""):gsub("%W+$", "")
        if #cleanedLine > 0 and not cleanedLine:match("^%-%-") then -- Игнорируем пустые строки и комментарии
            table.insert(fileList, cleanedLine)
        end
    end

    -- Создаем/очищаем папку astral
    printProgress("Перезапись директории...")
    if fs.exists(astralPath) then
        fs.remove(astralPath)
    end
    fs.makeDirectory(astralPath)

    -- Загружаем каждый файл
    printProgress("Перезапись файлов:(")
    local downloadedFiles = {}

    for i, filename in ipairs(fileList) do
        local fileUrl = repoUrl .. filename
        local filePath = fs.concat(astralPath, filename)

        success, err = pcall(function()
            local handle = internet.request(fileUrl)
            local file = io.open(filePath, "w")
            computer.pullSignal(0.2)
            for chunk in handle do
                file:write(chunk)
            end
            if handle then pcall(handle.close, handle) end
            file:close()
        end)

        if not success then
            printProgress(table.concat(downloadedFiles, ",") .. ") Ошибка: (Не удалось загрузить " .. filename .. ": " .. err .. ")]")
            return false
        end

        table.insert(downloadedFiles, filename)
        if i < #fileList then
            io.write(filename .. ",")
        else
            io.write(filename)
        end
    end

    printProgress(")... Конец установки... Успешно)]")
    return true
end

-- Функция для установки настроек
local function set()
    print("Настройка параметров:")

    -- Запрашиваем у пользователя данные
    io.write("Введите веб-адрес исполняемого кода: ")
    local codeUrl = io.read():gsub('"', '\\"')  -- Экранируем кавычки

    io.write("Введите веб-адрес отправки результата (может быть пустым): ")
    local resultUrl = io.read():gsub('"', '\\"')
    if resultUrl == "" then resultUrl = "nil" end

    io.write("Введите пароль (может быть пустым): ")
    local password = io.read():gsub('"', '\\"')
    if password == "" then password = "nil" end

    -- Сохраняем настройки в файл (теперь в корректном формате Lua)
    local cfgPath = fs.concat(shell.getWorkingDirectory(), "astral.cfg")
    local file = io.open(cfgPath, "w")
    if file then
        file:write("return {\n")
        file:write('    codeUrl = "'..codeUrl..'",\n')
        file:write('    resultUrl = '..(resultUrl ~= "nil" and '"'..resultUrl..'"' or "nil")..',\n')
        file:write('    password = '..(password ~= "nil" and '"'..password..'"' or "nil")..'\n')
        file:write("}\n")
        file:close()
        print("Настройки сохранены в " .. cfgPath)
    else
        print("Ошибка: Не удалось создать файл настроек")
    end
end

-- Функция для запуска программы
local function run()
    -- Проверяем наличие директории astral
    if not fs.exists(astralPath) then
        print("Ошибка: Директория astral не найдена. Сначала выполните установку:")
        print(currentFileName .. " install")
        return
    end

    -- Проверяем наличие файла настроек
    local cfgPath = fs.concat(shell.getWorkingDirectory(), "astral.cfg")
    if not fs.exists(cfgPath) then
        print("Файл настроек не найден. Запускаем настройку...")
        set()
        -- Повторно проверяем после создания
        if not fs.exists(cfgPath) then return end
    end

    -- Загружаем настройки как Lua-таблицу
    local settings = dofile(cfgPath)
    if not settings then
        print("Ошибка: Не удалось загрузить настройки из "..cfgPath)
        return
    end

    -- Ищем execute_server файл
    local executeFile
    for file in fs.list(astralPath) do
        if file:match("^execute_server") then
            executeFile = file
            break
        end
    end

    if not executeFile then
        print("Ошибка: Не найден файл execute_server в директории astral")
        return
    end

    -- Запускаем файл с параметрами через shell.execute
    local fullPath = fs.concat(astralPath, executeFile)
    print("Запуск "..fullPath.." с параметрами:")
    print("codeUrl = "..tostring(settings.codeUrl))
    print("resultUrl = "..tostring(settings.resultUrl))

    -- Формируем команду для нового процесса
    local cmd = string.format(
        'sleep 0.2 && lua "%s" "%s" "%s" "%s"',
        fs.concat(astralPath, executeFile),
        settings.codeUrl or "",
        settings.resultUrl or "",
        settings.password or ""
    )

    -- Запускаем через shell в фоне
    os.execute(cmd .. " &")

    -- Немедленный выход
    error("PROCESS_CHANGE", 0)
end

-- Обработка аргументов командной строки
local args = {...}

if #args == 0 or (args[1] == "help") then
    help()
elseif args[1] == "install" then
    install()
elseif args[1] == "set" then
    set()
elseif args[1] == "run" then
    run()
else
    print("Неизвестный аргумент. Используйте:")
    help()
end