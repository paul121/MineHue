minehue.config.lights = {}
minehue.config.lights.available = {}
minehue.config.lights.zones = {}

-- helper function get light ID from light name
minehue.get_light_id_by_name = function(table, name)
  for k, v in pairs(table) do
    if v.name == name then return k end
  end
  return nil
end

minehue.setZones = function(name, zone1, zone2, zone3)
  local table = minehue.config.lights.available
  zone1id = minehue.get_light_id_by_name(table, zone1)
  zone2id = minehue.get_light_id_by_name(table, zone2)
  zone3id = minehue.get_light_id_by_name(table, zone3)

  if zone1 ~= nil then
    minehue.config.lights.zones[1] = zone1id
  end
  if zone2 ~= nil then
    minehue.config.lights.zones[2] = zone2id
  end
  if zone3 ~= nil then
    minehue.config.lights.zones[3] = zone3id
  end
  minehue.save_config()
end
-- formspec for light config
minehue.get_light_formspec = function()

  local dropdownItems = ""
  for k, v in pairs(minehue.config.lights.available) do
    dropdownItems = dropdownItems..", "..v.name
  end
  minetest.debug(dropdownItems)

  local formspec = "size[6,8]"
		.."button[0,0;2,0.5;main;Back]"
    .."button_exit[4,0;2,0.5;minehue_exit;Exit]"
    .."label[0.5,1;Zone 1 Light - Global]"
    .."dropdown[0.5,1.5;5;minehue_zone1;Select A Light"..dropdownItems..";1]"

    .."label[0.5,2.5;Zone 2 Light - Global]"
    .."dropdown[0.5,3;5;minehue_zone2;Select A Light"..dropdownItems..";1]"

    .."label[0.5,4;Zone 3 Light - Aux]"
    .."dropdown[0.5,4.5;5;minehue_zone3;Select A Light"..dropdownItems..";1]"

    .."button_exit[0.5,5.5;5,0.5;minehue_get_all_lights;Get All Lights]"
    .."button[0.5,6.5;5,0.5;minehue_save_zones;Save Zones]"

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
      minehue.config.lights.available = nil
      minehue.config.lights.available = {}
      for k, v in pairs(result) do
        local light = {name=v.name, uniqueid=v.uniqueid}
--        minehue.config.lights.available
        minehue.config.lights.available[v.uniqueid] = {name=v.name}
  --      minetest.debug(k.." - "..v.name..", "..v.uniqueid..", ")
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
