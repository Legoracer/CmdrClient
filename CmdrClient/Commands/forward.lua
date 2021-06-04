local DEFAULT_DISTANCE = 10;

return {
	Name = "forward";
	Aliases = {"fwd"};
	Description = "Teleports you forward";
	Group = "Default";
	Args = {
        {
			Type = "number";
			Name = "Distance";
			Description = "The distance to teleport, default is " .. DEFAULT_DISTANCE .. " studs.";
			Optional = true;
		},
    };

	Run = function(context, distance)
		local mouse = context.Executor:GetMouse()
		local character = context.Executor.Character

		if not character then
			return "You don't have a character."
		end

        if not character.PrimaryPart then
            return "You don't have root part."
        end

		character:SetPrimaryPartCFrame(
            character.PrimaryPart.CFrame + character.PrimaryPart.CFrame.lookVector * (distance or DEFAULT_DISTANCE)
        )

		return "Teleported " .. tostring(distance or DEFAULT_DISTANCE) .. " studs forward."
	end
}