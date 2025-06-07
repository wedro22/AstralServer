-- Astral Installer for OpenComputers in GregTech New Horizons
-- Загружает последний релиз и устанавливает файлы в папку astral

local component = require("component")
local internet = require("internet")
local fs = require("filesystem")
local computer = require("computer")

-- Базовый URL репозитория
local repoUrl = "https://raw.githubusercontent.com/wedro22/AstralServer/master/lua/"

-- Функция для вывода прогресса в одну строку
local function printProgress(msg)
  io.write(msg .. " ")
end

-- Основная функция
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
  for line in releaseContent:gmatch("[^\r\n]+") do
    table.insert(fileList, line:gsub("%s+", "")) -- Удаляем пробелы и переносы
  end

  -- Создаем/очищаем папку astral
  printProgress("Перезапись директории...")
  local astralPath = fs.concat(fs.getWorkingDirectory(), "astral")

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

-- Запуск установки
install()