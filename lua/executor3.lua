local function safeExecute(code)
    local prints = {}
    local returns = {}
    local errors = nil

    -- Захватываем вывод print
    local oldPrint = print
    print = function(...)
        local parts = {}
        for i = 1, select('#', ...) do
            parts[i] = tostring(select(i, ...))
        end
        table.insert(prints, table.concat(parts, "\t"))
    end

    -- Выполняем код
    local success, results = pcall(function()
        local fn, err = load(code, "=dynamic", "t")
        if not fn then error(err) end
        return {fn()}  -- Собираем все возвращаемые значения в таблицу
    end)

    -- Восстанавливаем print
    print = oldPrint

    -- Обрабатываем результаты
    if not success then
        errors = tostring(results)
    else
        -- Преобразуем все возвращаемые значения в строки с переносами
        for i, val in ipairs(results) do
            returns[i] = tostring(val)
        end
    end

    return
        table.concat(prints, "\n"),  -- Все выводы print
        table.concat(returns, "\n"), -- Все возвращаемые значения, каждое с новой строки
        errors or ""                 -- Ошибки
end

return {safeExecute = safeExecute}