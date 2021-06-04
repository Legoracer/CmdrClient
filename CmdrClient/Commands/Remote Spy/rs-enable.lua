return {
	Name = "rs-enable";
	Aliases = {""};
	Description = "Enables remote spy.";
	Group = "Remote Spy";
	Args = {};

	Run = function(context)
		context.Cmdr.Registry.Libraries.RemoteSpy.Enabled = true
	end
}