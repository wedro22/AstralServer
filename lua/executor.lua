local function safeExecute(code)
  -- Создаем буфер для вывода
  local output = {}
  local function capture(...)
    local args = {...}
    for i = 1, select('#', ...) do
      table.insert(output, tostring(args[i]))
      if i < select('#', ...) then
        table.insert(output, "\t")
      end
    end
    table.insert(output, "\n")
  end

  -- Сохраняем оригинальные функции вывода
  local oldPrint = print
  local oldIoWrite = io.write

  -- Перехватываем вывод
  print = capture
  io.write = function(...) capture(...) return true end

  -- Выполняем код в защищенном режиме
  local success, result = pcall(function()
    local fn, err = load(code, "=dynamic", "t")
    if not fn then error(err) end
    return fn()
  end)

  -- Восстанавливаем оригинальные функции
  print = oldPrint
  io.write = oldIoWrite

  -- Добавляем результат выполнения или ошибку в вывод
  if not success then
    table.insert(output, "Execution error: " .. tostring(result) .. "\n")
  elseif result ~= nil then
    table.insert(output, "Return: " .. tostring(result) .. "\n")
  end

  -- Объединяем весь вывод в одну строку, предотвращая переполнение
  local combined = table.concat(output)
  if #combined > 1024 * 64 then -- Ограничение на 64KB
    combined = combined:sub(1, 1024 * 64) .. "\n...[output truncated]"
  end

  return combined
end

return {safeExecute = safeExecute}