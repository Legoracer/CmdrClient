-- A fully extensible and type-safe admin-commands console
-- @documentation https://github.com/evaera/Cmdr/blob/master/README.md
-- @source https://github.com/evaera/Cmdr
-- @rostrap Cmdr
-- @author evaera

-- Here be dragons

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

return function (Cmdr)
	local Util = Cmdr.Util

	local Window = require(script:WaitForChild("Window"))
	Window.Cmdr = Cmdr

	local AutoComplete = require(script:WaitForChild("AutoComplete"))(Cmdr)
	warn('AC Out:',AutoComplete)
	warn('Window Out:',Window)
	Window.AutoComplete = AutoComplete


	-- Sets the Window.ProcessEntry callback so that we can dispatch our commands out
	function Window.ProcessEntry(text)
		text = Util.TrimString(text)

		if #text == 0 then return end

		Window:AddLine(Window:GetLabel() .. " " .. text, false, Color3.fromRGB(255, 223, 93))

		Window:AddLine(Cmdr.Dispatcher:EvaluateAndRun(text, Player, {
			IsHuman = true
		}))
	end

	-- Sets the Window.OnTextChanged callback so we can update the auto complete
	function Window.OnTextChanged (text)
		local command = Cmdr.Dispatcher:Evaluate(text, Player, true)
		local arguments = Util.SplitString(text)
		local commandText = table.remove(arguments, 1)
		local atEnd = false
		if command then
			arguments = Util.MashExcessArguments(arguments, #command.Object.Args)

			atEnd = #arguments == #command.Object.Args
		end

		local entryComplete = commandText and #arguments > 0

		if text:sub(#text, #text):match("%s") and not atEnd then
			entryComplete = true
			arguments[#arguments + 1] = ""
		end

		if command and entryComplete then
			local commandValid, errorText = command:Validate()

			Window:SetIsValidInput(commandValid, ("Validation errors: %s"):format(errorText or ""))

			local acItems = {}

			local lastArgument = command:GetArgument(#arguments)
			if lastArgument then
				local typedText = lastArgument.RawSegments[#lastArgument.RawSegments]
				local items = lastArgument:GetAutocomplete()
				for i, item in pairs(items) do
					acItems[i] = {typedText, item}
				end

				local valid = true

				if #typedText > 0 then
					valid, errorText = lastArgument:Validate()
				end

				return AutoComplete:Show(acItems, {
					at = atEnd and #text - #typedText + (text:sub(#text, #text):match("%s") and -1 or 0);
					prefix = #lastArgument.RawSegments == 1 and lastArgument.Prefix or "";
					isLast = #command.Arguments == #command.ArgumentDefinitions and #typedText > 0;
					numArgs = #arguments;
					command = command;
					arg = lastArgument;
					name = lastArgument.Name .. (lastArgument.Required and "" or "?");
					type = lastArgument.Type.DisplayName;
					description = (valid == false and errorText) or lastArgument.Object.Description;
					invalid = not valid;
				})
			end
		elseif commandText and #arguments == 0 then
			Window:SetIsValidInput(true)
			local exactCommand = Cmdr.Registry:GetCommand(commandText)
			local exactMatch
			if exactCommand then
				exactMatch = {exactCommand.Name, exactCommand.Name, options = {
					name = exactCommand.Name;
					description = exactCommand.Description;
				}}
			end

			local acItems = {exactMatch}
			for _, cmd in pairs(Cmdr.Registry:GetCommandsAsStrings()) do
				if commandText:lower() == cmd:lower():sub(1, #commandText) and (exactMatch == nil or exactMatch[1] ~= commandText) then
					local commandObject = Cmdr.Registry:GetCommand(cmd)
					acItems[#acItems + 1] = {commandText, cmd, options = {
						name = commandObject.Name;
						description = commandObject.Description;
					}}
				end
			end

			return AutoComplete:Show(acItems)
		end

		Window:SetIsValidInput(false, "Invalid command. Use the help command to see all available commands.")
		AutoComplete:Hide()
	end

	Window:UpdateLabel()
	Window:UpdateWindowHeight()

	return {
		Window = Window;
		AutoComplete = AutoComplete;
	}
end
