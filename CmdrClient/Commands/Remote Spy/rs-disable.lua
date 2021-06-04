return {
	Name = "rs-disable";
	Aliases = {""};
	Description = "Disables remote spy.";
	Group = "Remote Spy";
	Args = {};

	Run = function(context)
		context.Cmdr.Registry.Libraries.RemoteSpy.Enabled = false
	end
}