return {
	Name = "rs-remote";
	Aliases = {""};
	Description = "Sets remote's setting to value.";
	Group = "Remote Spy";
	Args = {
        {
			Type = "string";
			Name = "Remote";
			Description = "Remote which you wish to edit."
		},

        {
            Type = "string";
            Name = "Setting";
            Description = "Setting which you wish to edit (Enabled, Every, AtMostEvery, IgnoreSame)."
        }
    };

	Run = function(context)
		context.Cmdr.Registry.Libraries.RemoteSpy.Enabled = true
	end
}