local RemoteSpy = {
    Enabled = false;
    SetUp = false;

    BaseRemote = {
        Enabled = true;
        Every = 1; -- Log every n remote calls
        AtMostEvery = 0; -- At most every n seconds
        IgnoreSame = false; -- Ignores remote if last one was same.

        __EveryCount = 0;
        __AtMostEveryTimestamp = 0;
        __LastCall = nil;
    };
    Remotes = {};

    Settings = {
        TabCharacter = "  ";
        NewlineCharacter = "\n";
    };
}

local metatable = getrawmetatable(game)

--// Custom functions aliases
local setreadonly = setreadonly or set_readonly
local make_writeable = make_writeable or function(t)
	setreadonly(t, false)
end
local make_readonly = make_readonly or function(t)
	setreadonly(t, true)
end
local detour_function = detour_function or replace_closure or hookfunction
local setclipboard = setclipboard or set_clipboard or writeclipboard
local get_namecall_method = get_namecall_method or getnamecallmethod
local protect_function = protect_function or newcclosureyield or newcclosure or function(...)
	return ...
end

local Original = {}
local Recorded = ""
local Methods = {
	RemoteEvent = "FireServer",
	RemoteFunction = "InvokeServer"
}

function CreateRemote(remote)
    RemoteSpy.Remotes[remote] = RemoteSpy.BaseRemote;
    return RemoteSpy.Remotes[remote];
end

local function IsValidCall(remote, method, args)
    if RemoteSpy.Enabled and (Methods[remote.ClassName] == method) then -- Valid remote call

        -- if remote then
        --     local remoteData = RemoteSpy.Remotes[remote] or CreateRemote();

        --     --// Every n calls.
        --     remoteData.__EveryCount += 1;
        --     if (remoteData.__EveryCount >= remoteData.Every) then
        --         remoteData.__EveryCount = 0;
        --     else
        --         return false;
        --     end

        --     --// Every n seconds.
        --     if (tick() - remoteData.__AtMostEveryTimestamp >= remoteData.AtMostEvery) then
        --         remoteData.__AtMostEveryTimestamp = tick();
        --     else
        --         return false;
        --     end

        --     --// Ignore same.
        --     if remoteData.IgnoreSame and remoteData.__LastCall then
        --         if remoteData.__LastCall == table.concat(args) then
        --             return false;
        --         end
        --     end
        --     remoteData.__LastCall = table.concat(args);
        -- end

        return true;
    end

    return false
end

local function GetInstanceName(object) --// Returns proper string wrapping for instances
	if object == nil then
		return ".NIL"
	end
	local isService = object.Parent == game
	local name = isService and object.ClassName or object.Name
	return (object ~= game and GetInstanceName(object.Parent) or "") .. (isService and ":GetService(\"%s\")" or (#name == 0 or name:match("[^%w]+") or name:sub(1, 1):match("[^%a]")) and "[\"%s\"]" or ".%s"):format(name)
end

local function Find(Table, Object, LastIndex)
	LastIndex = LastIndex or ""
	for Idx, Value in next, Table do
		if Object == Value then
			return LastIndex .. Idx
		elseif type(Value) == "table" then
			local Result = Find(Value, Object, Idx .. ".")
			if Result ~= nil then
				return LastIndex .. Result
			end
		end
	end
end

local renv = getrenv()

local function Parse(Object, TabCount) --// Convert the types into strings
	local Type = typeof(Object)
	local ParsedResult
	local TabCount = TabCount or 0
	if Type == "string" then
		ParsedResult = ("\"%s\""):format(Object)
	elseif Type == "Instance" then --// GetFullName except it's not handicapped
		ParsedResult = GetInstanceName(Object):sub(2)
	elseif Type == "table" then
		local Str = ""
		local Counter = 0
		TabCount = TabCount + 1
		for Idx, Obj in next, Object do
			Counter = Counter + 1
			Obj = Obj == Object and "THIS_TABLE" or Parse(Obj, TabCount)
			local TabCharacter = (Counter > 1 and "," or "") .. RemoteSpy.Settings.NewlineCharacter .. RemoteSpy.Settings.TabCharacter:rep(TabCount)
			if Counter ~= Idx then
				Str = Str .. ("%s[%s] = %s"):format(TabCharacter, Idx ~= Object and Parse(Idx, TabCount) or "THIS_TABLE", Obj)	 --maybe
			else
				Str = Str .. ("%s%s"):format(TabCharacter, Obj)
			end
		end
		TabCount = TabCount - 1
		ParsedResult = ("{%s}"):format(Str .. (#Str > 0 and RemoteSpy.Settings.NewlineCharacter .. RemoteSpy.Settings.TabCharacter:rep(TabCount) or ""))
	elseif Type == "CFrame" or Type == "Vector3" or Type == "Vector2" or Type == "UDim2" or Type == "Color3" or Type == "Vector3int16" or Type == "UDim" or Type == "Vector2int16" then
		ParsedResult = ("%s.new(%s)"):format(Type, tostring(Object))
	elseif Type == "userdata" then --// Remove __tostring fields to counter traps
		local Result
		local Metatable = getrawmetatable(Object)
		local __tostring = Metatable and rawget(Metatable, "__tostring")
		if __tostring then
			make_writeable(Metatable)
			Metatable.__tostring = nil
			ParsedResult = tostring(Object)
			rawset(Metatable, "__tostring", __tostring)
			if rawget(Metatable, "__metatable") ~= nil then
				make_readonly(Metatable)
			end
		else
			ParsedResult = tostring(Object)
		end
	elseif Type == "function" then
		ParsedResult = Find(renv, Object) or (
		[[(function()
			for Idx, Value in next, %s() do
				if type(Value) == "function" and tostring(Value) == "%s" then
					return Value
				end
			end
		end)()]]
		):gsub(
			"\n", 
			RemoteSpy.Settings.NewlineCharacter
		):gsub(
			"\t", 
			RemoteSpy.Settings.TabCharacter:rep(TabCount)
		):format(
			getgc and "getgc" or get_gc_objects and "get_gc_objects" or "debug.getregistry", 
			tostring(Object)
		)
	else
		ParsedResult = tostring(Object)
	end
	return ParsedResult
end

local function FormatText(Remote, Method, Arguments) --// Remote (Multiple types), Arguments (Table)
	local Stuff = ("\n<b>%s</b>:%s(%s)"):format(typeof(Remote) == "Instance" and Parse(Remote) or ("(%s)"):format(Parse(Remote)), Method, Parse(Arguments):sub(2, -2))
	if RemoteSpy.Settings.ShowScript and not PROTOSMASHER_LOADED then
		local Script = getcallingscript and getcallingscript() or rawget(getfenv(2), "script")
		if typeof(Script) == "Instance" then
			Stuff = Stuff .. ("\nScript: %s"):format(Parse(Script))
		end
	end
	return Stuff
end

function RemoteSpy:Write(remote, method, args)
    _ = (syn and syn.set_thread_identity or set_thread_context)(6)
    self.Cmdr.Interface.Window:AddLine(
        FormatText(remote, method, args), true
    )
end

function RemoteSpy:Init()
    do --// Anti detection for tostring ( tostring(FireServer, InvokeServer) )
        local original_function = tostring
        local new_function = function(obj)
            local Success, Result = pcall(original_function, Original[obj] or obj)
            if Success then
                return Result
            else
                error(Result:gsub(script.Name .. ":%d+: ", ""))
            end
        end
        original_function = detour_function(original_function, new_function)
        Original[new_function] = original_function
    end
    
    do
        for Class, Method in next, Methods do --// FireServer and InvokeServer hooking ( FireServer(Remote, ...) )
            local original_function = Instance.new(Class)[Method]
            local function new_function(self, ...)
                local Arguments = {...}
                if typeof(self) == "Instance" and IsValidCall(self, Method, Arguments) then
                    RemoteSpy:Write(self, Method, Arguments)
                end
                return original_function(self, ...)
            end
            new_function = protect_function(new_function)
            original_function = detour_function(original_function, new_function)
            Original[new_function] = original_function
            print("Hooked", Method)
        end
    end
    
    do --// Namecall hooking ( Remote:FireServer(...) )
        if get_namecall_method then
            local __namecall = metatable.__namecall
            local function new_function(self, ...)
                local Arguments = {...}
                local Method = get_namecall_method()
                if typeof(Method) == "string" and IsValidCall(self, Method, Arguments) then
                    RemoteSpy:Write(self, Method, Arguments)
                end
                return __namecall(self, ...)
            end
            new_function = protect_function(new_function)
            make_writeable(metatable)
            metatable.__namecall = new_function
            make_readonly(metatable)
            Original[new_function] = __namecall
            print("Hooked namecall")
        else
            warn("Couldn't hook namecall because exploit doesn't support 'getnamecallmethod'")
        end
    end
end

return RemoteSpy