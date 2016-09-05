local modpath = minetest.get_modpath(minetest.get_current_modname())
LOG_NOTICE  = "info"
LOG_VERBOSE = "verbose"
LOG_ACTION  = "action"
LOG_ERROR   = "error"
minetest.log(LOG_NOTICE,"MINEHUE: Initializing MineHue mod...")

-- Handle mod security if needed -- Similar to IRC Mod (some code taken from that mod)
local ie, req_ie = _G, minetest.request_insecure_environment
if req_ie then ie = req_ie() end
if not ie then
	error("The MineHue mod requires access to insecure functions in order "..
		"to work.  Please add the minehue mod to your secure.trusted_mods "..
		"setting or disable the minehue mod.")
end

ie.package.path =
		-- To find LuaIRC's init.lua
		modpath.."/?/init.lua;"
		-- For LuaIRC to find its files
		..modpath.."/?.lua;"
		..ie.package.path

-- The build of Lua that Minetest comes with only looks for libraries under
-- /usr/local/share and /usr/local/lib but LuaSocket is often installed under
-- /usr/share and /usr/lib.
if not rawget(_G, "jit") and package.config:sub(1, 1) == "/" then
	ie.package.path = ie.package.path..
			";/usr/share/lua/5.1/?.lua"..
			";/usr/share/lua/5.1/?/init.lua"
	ie.package.cpath = ie.package.cpath..
			";/usr/lib/lua/5.1/?.so"
end

-- Temporarily set require so that LuaIRC can access it
local old_require = require
require = ie.require
local http = ie.require("socket.http")
require = old_require



local HTTPApiTable = minetest.request_http_api()
-- local api
minehue = {}
minehue.config_file = minetest.get_modpath(minetest.get_current_modname()).."/config.txt"
minehue.config = {}
minehue.menu = {}
minehue.menu.lightconfig = "ambient"

assert(loadfile(minetest.get_modpath(minetest.get_current_modname()) .. "/lightconfig.lua"))(HTTPApiTable)
assert(loadfile(minetest.get_modpath(minetest.get_current_modname()) .. "/bridgeconfig.lua"))(HTTPApiTable)
assert(loadfile(minetest.get_modpath(minetest.get_current_modname()) .. "/lightcontrol.lua"))(http)


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
--water 232 grass 161
local biome_color = {["default:water_source"]={hue="232", sat = "254"},["default:water_flowing"]={hue="232", sat = "254"}, ["default:dirt_with_grass"]={hue="161", sat = "254"}, ["default:dirt"]={hue="37", sat = "254"}, ["default:sand"]={hue="51", sat = "254"} }

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
		 minehue.config.groups = {}
		 minehue.config.groups.all = {}
		 minehue.config.groups.ambient = {}
		 minehue.config.groups.effect = {}
		 minehue.config.biome_color = biome_color
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

minehue.get_formspec_tab = function(active)
	if not active then
    active = 1
  end
  active = tonumber(active)
  local t = {
    "bridge",
    "light"
  }
	return "tabheader[0.5,2;minehue_tab;Bridge Config, Light Config;"..active..";false;false]"
end

minehue.get_formspec = function(name, formspec)
	if not formspec then
		formspec = 1
	end
	formspec = tonumber(formspec)
	if formspec == 1 then
		minetest.show_formspec(name, "minehue:bridge", minehue.get_bridge_formspec())
	elseif formspec == 2 then
		minetest.show_formspec(name, "minehue:lights", minehue.get_light_formspec())
	end
end


-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	-- For minehue_tab handling --
	if fields.minehue_tab then
		minehue.get_formspec(name, fields.minehue_tab)
	end

	-- For Bridge Config Handling --
	if fields.minehue_connect then
		minehue.connect()
		minetest.show_formspec(name, formname,minehue.get_bridge_formspec(fields.minehue_tab))
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
		minetest.show_formspec(name, formname,minehue.get_bridge_formspec(fields.minehue_tab))
	end

	-- For Light Config Handling --
	if fields.minehue_light_tab then
		minetest.show_formspec(name, formname, minehue.get_light_formspec(fields.minehue_light_tab, fields.minehue_tab))
	end
	if fields.minehue_get_all_lights then
		if minehue.bridge_connected then
		  minehue.get_all_lights()
		end
		minetest.show_formspec(name, formname,minehue.get_light_formspec())
	end
	if fields.minehue_add_available_light then
		minehue.add_light_to_group(fields.minehue_available_lights)
		minetest.show_formspec(name, formname,minehue.get_light_formspec())
	end
	if fields.minehue_remove_light then
		minehue.remove_light_from_group(fields.minehue_group_lights)
		minetest.show_formspec(name, formname,minehue.get_light_formspec())
	end
end)


minehue.commandWrapper = function(name, params)
	if params == "bridge" or params == "" then
		minehue.get_formspec(name)
	elseif params == "lights" then
		minehue.get_formspec(name, 2)
	elseif params == "groups" then

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



local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime;
	if timer >= 0.5 then
		if minehue.bridge_connected then
			local player = minetest.get_player_by_name("singleplayer")
			local pos =  player.getpos(player)
			local foot = pos
			foot.y = foot.y - 1
			local target = minetest.get_node(foot)
			local head = pos
			head.y = head.y + 2.9 --plus 3, not 2, to account for offset of subtract 1 for foot
			local light = minetest.get_node_light(head, nil)
			local color = minehue.get_block_color(target.name)
			--minetest.chat_send_all("Minetest - "..target.name.." @ "..light)
			local factor = math.floor( (254/15) - 1 ) -- light does not set if value is not even, math.floor is required
			minehue.setLightState("ambient", light*factor, color)
			timer = 0
		end
	end
end)
