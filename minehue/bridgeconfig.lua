local HTTPApiTable = ...

minehue.bridge_connected = false
minehue.config.bridge = {}

minehue.connect = function(name)
	local host = minehue.config.bridge.hostname
	local username = minehue.config.bridge.username
	--local url = 'http://httpbin.org/post'
	local url = 'http://'..host..'/api/'..username..'/config'
	--minetest.chat_send_player(name, "Initializing HTTP Request to "..url)

	local HTTPReq = {
		url = url,
		timeout = 10,
	}

	local parse = function(req)
		local result = minetest.parse_json(req.data)
		if result then
			minehue.config.bridge.bridgid = result.mac
			minehue.save_config(name)
			minehue.bridge_connected = true;
			--minetest.chat_send_player(name, "Successful username retrieved: "..bridgeconfig["username"])
		end
		--minetest.show_formspec(name, "minehue:hueui",minehue.get_formspec())
	end
	local HTTPReqHandle = HTTPApiTable.fetch(HTTPReq, parse)
	--minetest.chat_send_player(name, "..Request sent.")
end


minehue.getBridgeUsername = function(name)
	local host = minehue.config.bridge.hostname
	--local url = 'http://httpbin.org/post'
	local url = 'http://'..host..'/api'
	local body = { devicetype=devicetype, username=username }
	minetest.chat_send_player(name, "Initializing HTTP Request to "..url)

	local HTTPReq = {
		url = url,
		timeout = 10,
		-- ^ Timeout for connection in seconds. Default is 3 seconds.
		post_data = '{"devicetype":"minetestclient"}'
		-- ^ Optional, if specified a POST request with post_data is performed.
		-- ^ Accepts both a string and a table. If a table is specified, encodes table
		-- ^ as x-www-form-urlencoded key-value pairs.
		-- ^ If post_data ist not specified, a GET request is performed instead.
	}

	local parse = function(req)
		local result = minetest.parse_json(req.data)
		if result[1].success then
			minehue.config.bridge.username = result[1].success.username
				minehue.save_config(name)
			minetest.chat_send_player(name, "Successful username retrieved: "..minehue.config.bridge.username)
		else
			minetest.chat_send_player(name, "Error")
			minetest.chat_send_player(name, req.data)
		end
		minetest.show_formspec(name, "minehue:bridge",minehue.get_bridge_formspec())
	end

	local HTTPReqHandle = HTTPApiTable.fetch(HTTPReq, parse)
	minetest.chat_send_player(name, "..Request sent.")

end

minehue.setHostname = function(name, hostname)
	minehue.config.bridge.hostname = hostname
	minehue.save_config()
	minetest.chat_send_player(name, "Bridge hostname set to "..hostname)
end

minehue.setUsername = function(name, username)
	minehue.config.bridge.username = username
	minehue.save_config()
	minetest.chat_send_player(name, "Bridge Username set to "..username)
end


-- formspec for bridge config
minehue.get_bridge_formspec_content = function()
	local connected_color = "red"
	if minehue.bridge_connected then
		connected_color = "green"
	end
	local formspec = "field[0.5,2.5;5,0.5;minehue_hostname;Bridge IP/Hostname;"..minehue.config.bridge.hostname.."]"
		.."field[0.5,3.5;5,0.5;minehue_username;Bridge Username;"..minehue.config.bridge.username.."]"
		.."button_exit[1.5,4;3,0.5;minehue_get_username;Get Username]"
		.."button[0,4;3,0.5;minehue_save;Save Config]"
		.."button_exit[3,5;3,0.5;minehue_reload;Reload Config]"
		.."box[0,6;1,1;"..connected_color.."]"
		.."button_exit[1,6;5,0.5;minehue_connect;Connect]"

	return formspec
end
