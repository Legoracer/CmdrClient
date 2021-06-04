-- A fully extensible and type-safe admin-commands console
-- @documentation https://github.com/evaera/Cmdr/blob/master/README.md
-- @source https://github.com/evaera/Cmdr
-- @rostrap Cmdr
-- @author evaera

local Util = require(script.Parent.Parent.Shared.Util)

local combinedInputEnums = Enum.UserInputType:GetEnumItems()

for _, e in pairs(Enum.KeyCode:GetEnumItems()) do
	combinedInputEnums[#combinedInputEnums + 1] = e
end

local userInputType = {
	Transform = function (text)
		local findEnum = Util.MakeFuzzyFinder(combinedInputEnums)

		return findEnum(text)
	end;

	Validate = function (enums)
		return #enums > 0
	end;

	Autocomplete = function (enums)
		return Util.GetNames(enums)
	end;

	Parse = function (enums)
		return enums[1];
	end;
}

return function (cmdr)
	cmdr:RegisterType("userInput", userInputType)
	cmdr:RegisterType("userInputs", Util.MakeListableType(userInputType))
end