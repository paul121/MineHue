local HTTPApiTable = ...

minehue.config.lights = {}
minehue.config.lights.available = {}
minehue.config.lights.zones = {}

local lightconfig_menu = {
  "ambient",
  "effect"
}

-- helper function get light ID from light name
minehue.get_light_id_by_name = function(table, name)
  for k, v in pairs(table) do
    if v.name == name then return k end
  end
  return nil
end

minehue.get_light_by_id = function(table, id)
  for k, v in pairs(table) do
    if v.id == id then
      return {id=v.id, name=v.name}, k
    end
  end
  return nil, nil
end

minehue.get_light_formspec = function(active)
  if not active then
    minetest.debug("No light menu specified")
    active = 1
  end
  active = tonumber(active)

  local group = lightconfig_menu[active]
  minehue.menu.lightconfig = group

  local list_items = ""
  for k, v in pairs(minehue.config.lights) do
    list_items = v.id.." - "..v.name..","..list_items
  end
  local group_items = ""

  for k, v in pairs(minehue.config.groups[group]) do
    group_items = group_items..v.id.." - "..v.name..","
  end
  minetest.debug("Available lights: "..list_items..", "..group.." lights: "..group_items)
  local tab = minehue.get_formspec_tab(2)
  local formspec = "size[6,8]"
		.."button[0,0;2,0.5;main;Back]"
    .."button_exit[4,0;2,0.5;minehue_exit;Exit]"
    ..tab
    .."tabheader[0.5,3;minehue_light_tab;Ambient Lights, Effect Lights;"..active.."]"
    .."label[0.5,3;Available Lights]"
    .."dropdown[0,3.5;3;minehue_available_lights;"..list_items..";1]"
    --.."textlist[0,3.5;3,1;minehue_available_lights;"..list_items.."]"
    .."button_exit[3.5,3;2,2;minehue_add_available_light;Add Selected Light\n to "..group.." group]"

    .."label[0.5,4.5;"..group.." Lights]"
    .."dropdown[0,5;3;minehue_group_lights;"..group_items..";1]"
    --.."textlist[0,5;3,1;minehue_remove_light;"..group_items.."]"
    .."button_exit[3.5,4.5;2,2;minehue_remove_light;Remove Selected Light\n from "..group.." group]"

    .."button_exit[0.5,6.5;5,0.5;minehue_get_all_lights;Get All Lights]"

	return formspec
end

minehue.get_all_lights = function(name)
	local host = minehue.config.bridge.hostname
	local username = minehue.config.bridge.username
	--local url = 'http://httpbin.org/post'
	local url = 'http://'..host..'/api/'..username..'/lights'
	--minetest.chat_send_player(name, "Initializing HTTP Request to "..url)

	local HTTPReq = {
		url = url,
		timeout = 10,
	}

	local parse = function(req)
		local result = minetest.parse_json(req.data)
		if result then
      local x = 0
      minehue.config.lights = nil
      minehue.config.lights = {}
      for k, v in pairs(result) do
        local light = {name=v.name, id=k}
--        minehue.config.lights.available
        minehue.config.lights[x] = light
  --      minetest.debug(k.." - "..v.name..", "..v.uniqueid..", ")
        x = x + 1;
      end
      minehue.save_config()
			--minetest.debug(minehue.config.lights.available[2].name)
			--minetest.chat_send_player(name, "Successful username retrieved: "..bridgeconfig["username"])
		end
		--minetest.show_formspec(name, "minehue:hueui",minehue.get_formspec())
	end
	local HTTPReqHandle = HTTPApiTable.fetch(HTTPReq, parse)
	--minetest.chat_send_player(name, "..Request sent.")
end


minehue.add_light_to_group = function(lightid)
  local groupname = minehue.menu.lightconfig
  lightid = string.sub(lightid, 0,1)
  minetest.debug(lightid)

  local light = minehue.get_light_by_id(minehue.config.lights, lightid)
  if minehue.get_light_by_id(minehue.config.groups[groupname], lightid) == nil then
    table.insert(minehue.config.groups[groupname], light)
  else
    minetest.debug("Light already exists in this group! Cannot add.")
  end
  minehue.save_config()
end

minehue.remove_light_from_group = function(lightid)
  local groupname = minehue.menu.lightconfig
  lightid = string.sub(lightid, 0,1)
  --minetest.debug(lightid)

  local light, idx = minehue.get_light_by_id(minehue.config.lights, lightid)
  minetest.debug(idx)
  if idx ~= nil then
    table.remove(minehue.config.groups[groupname], idx)
  end
  minehue.save_config()
end
