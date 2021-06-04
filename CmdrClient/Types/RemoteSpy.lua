return function (cmdr)
    local remoteSpySettingType = {
        Transform = function (text)
            return tostring(text)
        end;

        Validate = function (value)
            local t = {
                Enabled = true;
                Every = true; -- Log every n remote calls
                AtMostEvery = true; -- At most every n seconds
                IgnoreSame = false; -- Ignores remote if last one was same.
            }

            for _,x in next, t do
                if x:lower() == value:lower() then return true end
            end

            return false
        end;

        Parse = function (value)
            return value
        end
    }

    local rs = cmdr.Libraries.RemoteSpy;
    print(rs)
    
    local remoteSpyRemoteType = {
        Transform = function (text)
            return tostring(text)
        end;

        Validate = function (value)
            for remote, settings in next, rs.Remotes do
                if remote.Name == value or remote:GetFullName() == value then
                    return true
                end
            end

            return false
        end;

        Parse = function (value)
            for remote, settings in next, rs.Remotes do
                if remote.Name == value or remote:GetFullName() == value then
                    return {remote, settings};
                end
            end
        end
    }

    cmdr:RegisterType("remoteSpyRemote", remoteSpyRemoteType)
	cmdr:RegisterType("remoteSpySetting", remoteSpySettingType)
end