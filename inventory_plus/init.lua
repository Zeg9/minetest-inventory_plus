--[[

Inventory Plus for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-particles
License: GPLv3

]]--


-- expose api
inventory_plus = {}

-- define buttons
inventory_plus.buttons = {}

-- register_button
inventory_plus.register_button = function(player,name,label)
	local player_name = player:get_player_name()
	if inventory_plus.buttons[player_name] == nil then
		inventory_plus.buttons[player_name] = {}
	end
	inventory_plus.buttons[player_name][name] = label
end

-- set_inventory_formspec
inventory_plus.set_inventory_formspec = function(player,formspec)
	if minetest.setting_getbool("creative_mode") then
		-- if creative mode is on then wait a bit
		minetest.after(0.01,function()
			player:set_inventory_formspec(formspec)
		end)
	else
		player:set_inventory_formspec(formspec)
	end
end

-- get_formspec
inventory_plus.get_formspec = function(player,page)
	local formspec = "size[8,7.5]"
	
	-- player inventory
	formspec = formspec .. "list[current_player;main;0,3.5;8,4;]"

	-- craft page
	if page=="craft" then
		formspec = formspec
			.."button[0,0;2,0.5;main;Back]"
			.."list[current_player;craft;3,0;3,3;]"
			.."list[current_player;craftpreview;7,1;1,1;]"
	end
	
	-- creative page
	if page=="creative" then
		return player:get_inventory_formspec()
			.."button[5,0;2,0.5;main;Back]"
			.."label[6,1.5;Trash:]"
			.."list[detached:trash;main;6,2;1,1;]"
			.."label[5,1.5;Refill:]"
			.."list[detached:refill;main;5,2;1,1;]"
	end
	
	-- main page
	if page=="main" then
		-- buttons
		local x,y=0,0
		for k,v in pairs(inventory_plus.buttons[player:get_player_name()]) do
			formspec = formspec .. "button["..x..","..y..";2,0.5;"..k..";"..v.."]"
			x=x+2
			if x == 8 then
				x=0
				y=y+1
			end
		end
	end
	
	return formspec
end

-- trash slot
inventory_plus.trash = minetest.create_detached_inventory("trash", {
	allow_put = function(inv, listname, index, stack, player)
		if minetest.setting_getbool("creative_mode") then
			return stack:get_count()
		else
			return 0
		end
	end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, nil)
	end,
})
inventory_plus.trash:set_size("main", 1)

-- refill slot
inventory_plus.refill = minetest.create_detached_inventory("refill", {
	allow_put = function(inv, listname, index, stack, player)
		if minetest.setting_getbool("creative_mode") then
			return stack:get_count()
		else
			return 0
		end
	end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, ItemStack(stack:get_name().." "..stack:get_stack_max()))
	end,
})
inventory_plus.refill:set_size("main", 1)


-- register_on_joinplayer
minetest.register_on_joinplayer(function(player)
	inventory_plus.register_button(player,"craft","Craft")
	if minetest.setting_getbool("creative_mode") then
		inventory_plus.register_button(player,"creative_prev","Creative")
	end
	minetest.after(1,function()
		local default = minetest.setting_get("inventory_default") or "craft"
		inventory_plus.set_inventory_formspec(player,inventory_plus.get_formspec(player,default))
	end)
end)

-- register_on_player_receive_fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	-- main
	if fields.main then
		inventory_plus.set_inventory_formspec(player, inventory_plus.get_formspec(player,"main"))
		return
	end
	-- craft
	if fields.craft then
		inventory_plus.set_inventory_formspec(player, inventory_plus.get_formspec(player,"craft"))
		return
	end
	-- creative
	if fields.creative_prev or fields.creative_next then
		minetest.after(0.01,function()
			inventory_plus.set_inventory_formspec(player, inventory_plus.get_formspec(player,"creative"))
		end)
		return
	end
end)

-- log that we started
minetest.log("action", "[MOD]"..minetest.get_current_modname().." -- loaded from "..minetest.get_modpath(minetest.get_current_modname()))