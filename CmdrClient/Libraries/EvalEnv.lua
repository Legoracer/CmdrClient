local e = {}

e.json = {
    encode = function(...)
        return game:GetService("HttpService"):JSONEncode(...)
    end;

    decode = function(...)
        return game:GetService("HttpService"):JSONDecode(...)
    end;
}

e.keys = function(t)
    local keys = {}

    for k, _ in next, t do
        table.insert(keys, k)
    end

    return keys
end
e.values = function(t)
    local values = {}

    for _, v in next, t do
        table.insert(values, v)
    end

    return values
end
e.join = table.concat;

return e