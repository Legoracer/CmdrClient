return {
	Name = "evalr";
	Aliases = {"="};
	Description = "Evaluates code and prints returned value.";
	Group = "Default";
	Args = {
		{
			Type = "string";
			Name = "Code";
			Description = "The code."
		},
	};

	Run = function(context, text)
		local f = loadstring("return " .. text)
		local e = getfenv(f)
		e.Context = context;
		e.Cmdr = context.Cmdr;
	    
        for k, v in next, context.Cmdr.Registry.Libraries.EvalEnv do
            e[k] = v;
        end

        local r, e = pcall(f);
        if not r then
            return "Error: " .. e;
        else
            return "Returned: " .. tostring(e)
        end
	end
}