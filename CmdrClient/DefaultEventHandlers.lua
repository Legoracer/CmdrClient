-- A fully extensible and type-safe admin-commands console
-- @documentation https://github.com/evaera/Cmdr/blob/master/README.md
-- @source https://github.com/evaera/Cmdr
-- @rostrap Cmdr
-- @author evaera

local StarterGui = game:GetService("StarterGui")
local Window = require(script.Parent.CmdrInterface.Window)

return function (Cmdr)
	Cmdr:HandleEvent("Message", function (text)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = ("[Announcement] %s"):format(text);
			Color = Color3.fromRGB(249, 217, 56);
		})
	end)

	Cmdr:HandleEvent("AddLine", function (...)
		Window:AddLine(...)
	end)
end