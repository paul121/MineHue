local http = ...

minehue.setLightState = function(group, brightness, color)
	local host = minehue.config.bridge.hostname
	local username = minehue.config.bridge.username
	local onBool = "true"
	if brightness == 0 then
		onBool = "false"
	end
	local data ='{"on":'..onBool..', '..color..'"bri": '..brightness..'}'



	--minetest.debug("Setting: "..data)
	local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded";
        ["Content-Length"] = string.len(data);
      }

	local respbody = {}
	if minehue.config.groups[group] ~= null then
		for k,v in pairs(minehue.config.groups[group]) do
			local url = 'http://'..host..'/api/'..username..'/lights/'..v.id..'/state'
			local client, code, headers, status = http.request{
			  url = url,
			  source = ltn12.source.string(data),
				sink = ltn12.sink.table(respbody),
				headers = headers,
			  method = "PUT"
			}
			--for k, v in pairs(respbody) do
		  --  minetest.chat_send_all(k.."="..v)
		  --end
			minetest.chat_send_all(k..": "..status)
		end
	else
		minetest.debug("Invalid group -- config does not exist.")
	end

end


minehue.get_block_color = function(block_name)
	if minehue.config.biome_color[block_name] ~= nil then
		--minetest.debug(minehue.config.biome_color[block_name].hue)
		local target = minehue.config.biome_color[block_name]
		local hue = math.floor(182*target.hue)
		return '"hue":'..hue..', "sat":'..target.sat..','
	else
		--minetest.debug("Unknown block")
		return ''
	end
end
