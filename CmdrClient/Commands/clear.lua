local Players = game:GetService("Players")

return {
	Name = "clear",
	Aliases = {},
	Description = "Clear all lines above the entry line of the Cmdr window.",
	Group = "Default",
	Args = {},
	Run = function()
		local player = Players.LocalPlayer
		local gui = game.CoreGui:WaitForChild("Cmdr")
		local frame = gui:WaitForChild("Frame")

		if gui and frame then
			for _, child in pairs(frame:GetChildren()) do
				if child.Name == "Line" and child:IsA("TextLabel") then
					child:Destroy()
				end
			end
		end
		return ""
	end
}