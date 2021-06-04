return {
	Name = "teleport";
	Aliases = {"tp"};
	Description = "Teleports you to a specified player.";
	Group = "Default";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "Player to teleport to."
		},
	};

	Run = function(_, targetPlayer)
		local localPlayer = game:GetService("Players").LocalPlayer

        local localCharacter = localPlayer.Character
        local targetCharacter = targetPlayer.Character

        if localCharacter and targetCharacter then
            local targetRoot = targetCharacter.PrimaryPart
            if targetRoot then
                localCharacter:SetPrimaryPartCFrame(
                    targetRoot.CFrame
                )

                return ("Teleported to %s"):format(targetPlayer.Name)
            end

            return "Target player is missing root part."
        end

        return "You or target player is not spawned in."
	end
}