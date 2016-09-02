


HTTPApiTable = minetest.request_http_api()
-- local api
minehue = {}
minehue.config_file = minetest.get_modpath(minetest.get_current_modname()).."/config.txt"
minehue.config = {}

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/lightconfig.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/bridgeconfig.lua")


minehue.save_config = function(name)
	local file = io.open(minehue.config_file, "w")
	if file then
		 file:write(minetest.serialize(minehue.config))
		 file:close()
	end
	if name then
		minetest.chat_send_player(name, "Saved config to "..minehue.config_file)
	end
end

-- load Hue Bridge data

minehue.load_config = function(name)
	local file = io.open(minehue.config_file, "r")
	if file then
		 local table = minetest.deserialize(file:read("*all"))
		 if type(table) == "table" then
				return table
		 end
 	else
		 minehue.config.bridge.hostname = "temp"
		 minehue.config.bridge.username = "temp"
		 minehue.config.bridge.bridgeid = "temp"
     minehue.config.lights = {}
     minehue.config.lights.available = {}
		 minehue.config.lights.zones = {}
		 minehue.save_config()
		 return minehue.config
	end
	if name then
		minetest.chat_send_player(name, "Loaded config to "..minehue.config_file)
	end
	return {}
end

minehue.config = minehue.load_config("")
if minehue.config.bridge.bridgeid ~= "temp" then
	minehue.connect()
end




-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	-- For Bridge Config Handling --
	if fields.minehue_connect then
		minehue.connect()
		minetest.show_formspec(name, formname,minehue.get_bridge_formspec())
	end
	if fields.minehue_get_username then
		minehue.getBridgeUsername(name)
	end
	if fields.minehue_save then
		minehue.setHostname(name, fields.minehue_hostname)
		--bridgeconfig["ip"] = fields.minehue_ip
		minehue.setUsername(name, fields.minehue_username)
		--bridgeconfig["username"] = fields.minehue_username
		minehue.save_config(name)
	end
	if fields.minehue_reload then
		minetest.show_formspec(name, formname,minehue.get_bridge_formspec())
	end

	-- For Light Config Handling --
	if fields.minehue_get_all_lights then
		if minehue.bridge_connected then
		  minehue.get_all_lights()
		end
		minetest.show_formspec(name, "minehue:lights",minehue.get_light_formspec())
	end
	if fields.minehue_save_zones then
		minehue.setZones(name, fields.minehue_zone1, fields.minehue_zone2, fields.minehue_zone3)
	end
	-- For Inventory Plus Menu Handling --
	if fields.mine_hue then
		inventory_plus.set_inventory_formspec(player, minehue.get_bridge_formspec())
	end
end)


minetest.register_on_joinplayer(function(player)
	-- add inventory_plus page
	inventory_plus.register_button(player,"mine_hue","Hue Control")
end)




minehue.commandWrapper = function(name, params)
	if params == "bridge" or params == "" then
		minetest.show_formspec(name, "minehue:bridge",minehue.get_bridge_formspec())
	elseif params == "lights" then
		minetest.show_formspec(name, "minehue:lights",minehue.get_light_formspec())
	end

end

-- register minehue chat command
minetest.register_chatcommand("minehue", {
	privs = {
		interact = true
	},
	func = function(name, params)
		minehue.commandWrapper(name, params)
	end
})











minehue.setLightState = function(lightid, brightness)
	local host = minehue.config.bridge.hostname
	local username = minehue.config.bridge.username
	--local url = 'http://'..host..'/api/'..username..'/lights/'..lightid..'/state'
	local url = 'http://httpbin.org/post'
	--minetest.chat_send_player(name, "Initializing HTTP Request to "..url)

	local HTTPReq = {
		url = url,
		timeout = 10,
		-- ^ Timeout for connection in seconds. Default is 3 seconds.
		post_data = '{"on": true,"bri": '..brightness..'}'
		-- ^ Optional, if specified a POST request with post_data is performed.
		-- ^ Accepts both a string and a table. If a table is specified, encodes table
		-- ^ as x-www-form-urlencoded key-value pairs.
		-- ^ If post_data ist not specified, a GET request is performed instead.
	}

	local parse = function(req)
		local result = minetest.parse_json(req.data)
		minetest.debug(req.data)
	end

	local HTTPReqHandle = HTTPApiTable.fetch(HTTPReq, parse)
	--minetest.chat_send_player(name, "..Request sent.")

end





local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime;
	if timer >= 5 then
		-- Send "Minetest" to all players every 5 seconds
		local player = minetest.get_player_by_name("singleplayer")
		local pos =  player.getpos(player)
		local light = minetest.get_node_light(pos, nil)
		local type = minetest.get_node(pos)
		minetest.chat_send_all("Minetest - "..type.name.." @ "..light)
		local factor = (254/15) - 1
		minehue.setLightState("00:17:88:01:00:d4:12:08-0a", light*factor)
		timer = 0
	end
end)
