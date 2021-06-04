local RequireCache = {}

function fakeRequire(moduleScript)
    if RequireCache[moduleScript] then
		return RequireCache[moduleScript]
	end
    local source = moduleScript.source
    local func = loadstring(source)

    local env = setmetatable({}, {
		__index=getgenv();
    })

    env.script = moduleScript
    env.require = fakeRequire

    setfenv(func, env)
    local result = func()
    RequireCache[moduleScript] = result

    return result
end

local Module = game:GetObjects("rbxassetid://4314664297")[1]
return fakeRequire(Module)
