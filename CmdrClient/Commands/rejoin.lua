return {
	Name = "rejoin";
	Aliases = {"rj"};
	Description = "Rejoins you to the game.";
	Group = "Default";
	Args = {};

	Run = function(_, min, max)
		game:GetService("TeleportService"):Teleport(game.PlaceId)
	end
}