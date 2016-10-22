local formspec_tabs = {
	{tabname="Bridge Config", name="minehue_bridgeconfig", content=function() return minehue.get_bridge_formspec_content() end},
	{tabname="Light Config", name="minehue_lightconfig", content=function() return minehue.get_light_formspec_content() end},
	{tabname="Light Control", name="minehue_lightcontrol", content=function() return "" end}
}


local made_formspec_tab = "temp"

local make_formspec_tab = function(active)
	if not active then active = 1 end
	made_formspec_tab = "size[6,8]".."tabheader[0,0;minehue_tabheader;"
	local tabs= ""
	for k,v in pairs(formspec_tabs) do
		tabs = tabs..","..v.tabname
	end
	tabs = string.sub(tabs, 2) -- remove comma from first interation of loop
	made_formspec_tab = made_formspec_tab..tabs..";"..active.."]"
end
make_formspec_tab()


minehue.make_formspec = function(int)
	if int == 0 or int == nil then int = 1 end
	make_formspec_tab(int)
	local name = formspec_tabs[int].name
	return made_formspec_tab..formspec_tabs[int].content()
end

minehue.get_formspec = function(name, tabnum)
	local formspec = minehue.make_formspec(tonumber(tabnum))
	minetest.show_formspec(name, "minehue_settings", formspec)
end

-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	-- For minehue_tab handling --
	if fields.minehue_tabheader then
		minehue.get_formspec(name, fields.minehue_tabheader)
	end

	-- For Bridge Config Handling --
	if fields.minehue_connect then
		minehue.connect()
		minehue.get_formspec(name, fields.minehue_tabheader)
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
		minehue.get_formspec(name, fields.minehue_tabheader)
	end

	-- For Light Config Handling --
	if fields.minehue_light_tab then
		minehue.session.lighttab = tonumber(fields.minehue_light_tab)
		minehue.get_formspec(name, 2)
	end
	if fields.minehue_get_all_lights then
		if minehue.bridge_connected then
		  minehue.get_all_lights()
		end
		minehue.get_formspec(name, 2)
	end
	if fields.minehue_add_available_light then
		minehue.add_light_to_group(fields.minehue_available_lights)
		minehue.get_formspec(name, 2)
	end
	if fields.minehue_remove_light then
		minehue.remove_light_from_group(fields.minehue_group_lights)
		minehue.get_formspec(name, 2)
	end
end)


minehue.commandWrapper = function(name, params)
	if params == "bridge" then
		minehue.get_formspec(name, 1)
	elseif params == "lights" then
		minehue.get_formspec(name, 2)
	else
		minehue.get_formspec(name)
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
