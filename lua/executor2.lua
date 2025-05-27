local function safeExecute(code)
    local prints = {}
    local returns = nil
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
    local success, result = pcall(function()
        local fn, err = load(code, "=dynamic", "t")
        if not fn then error(err) end
        return fn()
    end)

    -- Восстанавливаем print
    print = oldPrint

    -- Обрабатываем результаты
    if not success then
        errors = tostring(result)
    elseif result ~= nil then
        returns = tostring(result)
    end

    return
        table.concat(prints, "\n"),  -- Все выводы print
        returns or "",              -- Возвращаемое значение
        errors or ""                -- Ошибки
end

return {safeExecute = safeExecute}