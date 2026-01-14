--[[
## Interface: 30300
## Title: GimmeBuffsPls
## Version: 0.0.1
## Notes: /buff
## Author: Me
]]

local addon_name = "GimmeBuffsPls"

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function dump(object)
	if type(object) ~= 'table' then
		return tostring(object)
	end
	local s = '{ '
	for k, v in pairs(object) do
		if type(k) ~= 'number' then k = '"' .. k .. '"' end
		s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
	end
	return s .. '} '
end

local function merge_tables(table1, table2)
	local union = {}
	for k, v in pairs(table1) do
		union[k] = v
	end
	for k, v in pairs(table2) do
		union[k] = v
	end
	return union
end

local function get_keys(mapping)
	local keys = {}
	for key, _ in pairs(mapping) do
		table.insert(keys, key)
	end
	return keys
end

local function concat(words, separator, separatorLast)
	if separator == nil then separator = "" end
	if separatorLast == nil then separatorLast = separator end
	if #words < 2 then
		return table.concat(words, separator)
	end
	return table.concat(words, separator, 1, #words - 1) .. separatorLast .. words[#words]
end

local is_in_raid = true;

local function get_party_members()
	is_in_raid = false;
	local members = {}
	members[UnitName("player")] = string.lower(select(2, UnitClass("player")))
	for i = 1, 60 do
		local member = UnitName("party" .. i)
		if member == nil then break end
		local _, class = UnitClass(member)
		if class ~= nil then
			members[member] = string.lower(class)
		end
	end
	for i = 1, 60 do
		local member = UnitName("raid" .. i)
		if member == nil then break end
		local _, memberClass = UnitClass(member)
		if memberClass ~= nil then
			members[member] = string.lower(memberClass)
		end
		is_in_raid = true
	end
	return members
end

local function get_classes(members)
	local classes = {
		warrior = 0,
		hunter = 0,
		priest = 0,
		mage = 0,
		paladin = 0,
		rogue = 0,
		shaman = 0,
		warlock = 0,
		druid = 0,
		deathknight = 0,
	}
	for _, class in pairs(members) do
		classes[class] = classes[class] + 1
	end
	return classes
end

local function get_missing_buffs(player, classes)
	if player == nil then player = UnitName("player") end
	if classes == nil then classes = get_classes(get_party_members()) end
	local class = string.lower(select(2, UnitClass(player)))
	local missing_self_buffs = {}
	local missing_party_buffs = {}

	-- Party buffs
	local function check(spell_id, spell_names)
		for _, spell_name in ipairs(spell_names) do
			if UnitBuff(player, spell_name) ~= nil then
				return true
			end
		end
		missing_party_buffs[spell_names[1]] = spell_id
		return false
	end
	if classes.priest > 0 then
		check(48169, { "Shadow Protectin", "Prayer of Shadow Protection" })
		check(10938, { "Power Word: Fortitude", "Prayer of Fortitude" })
		check(48073, { "Divine Spirit", "Prayer of Spirit" })
	end
	if classes.druid > 0 then
		check(48469, { "Mark of the Wild", "Gift of the Wild" })
	end
	if classes.paladin >= 1 then
		check(20217, { "Blessing of Kings", "Greater Blessing of Kings" })
		if classes.paladin >= 2 then
			check(19742, { "Blessing of Wisdom", "Greater Blessing of Wisdom" })
			if classes.paladin >= 3 then
				-- check(1038, { "Blessing of Salvation", "Greater Blessing of Salvation", "Blessing of Sanctuary" })
				check(20911, { "Blessing of Sanctuary", "Greater Blessing of Sanctuary" })
			end
		end
	end
	if classes.mage > 0 then
		check(42995, { "Arcane Intellect", "Arcane Brilliance", "Dalaran Brilliance" })
		if class == "mage" and classes.mage > 1 then
			check(54646, { "Focus Magic" })
		end
	end

	-- Self buffs
	function check(spell_id, spell_names)
		for _, spell_name in ipairs(spell_names) do
			if UnitBuff(player, spell_name) ~= nil then
				return false
			end
		end
		missing_party_buffs[spell_names[1]] = nil
		missing_self_buffs[spell_names[1]] = spell_id
		return false
	end

	if class == "mage" then
		if is_in_raid then
			check(53755, { "Flask of the Frost Wyrm" })
		end
		check(42995, { "Arcane Intellect", "Arcane Brilliance", "Dalaran Brilliance" })
		check(43046, { "Molten Armor", "Ice Armor" })
	elseif class == "druid" then
		check(48469, { "Mark of the Wild", "Gift of the Wild" })
	elseif class == "priest" then
		check(48169, { "Shadow Protectin", "Prayer of Shadow Protection" })
		check(48161, { "Power Word: Fortitude", "Prayer of Fortitude" })
		check(48073, { "Divine Spirit", "Prayer of Spirit" })
	elseif class == "paladin" then
		check(20217, {
			"Blessing of Kings", "Greater Blessing of Kings", "Blessing of Wisdom", "Greater Blessing of Wisdom",
			"Blessing of Salvation", "Greater Blessing of Salvation", "Blessing of Sanctuary"
		})
	end
	if is_in_raid then
		check(57399, { "Well Fed" })
	end
	return missing_self_buffs, missing_party_buffs
end

local function concat_bufflinks(buffs)
	local links = {}
	for _, spell_id in pairs(buffs) do
		local link, _ = GetSpellLink(spell_id)
		table.insert(links, link)
	end
	return concat(links, ", ", " and ")
end

local function ask_for_buffs()
	local self_buffs, party_buffs = get_missing_buffs()
	if next(party_buffs) == nil then
		print("You miss no buffs from your teamates")
	else
		local message = "Gimme " .. concat_bufflinks(party_buffs) .. " pls"
		SendChatMessage(message, is_in_raid and "RAID" or "PARTY")
	end
	if next(self_buffs) ~= nil then
		print("You can buff yourself with " .. concat_bufflinks(self_buffs))
	end
end

local function check_self_buffs()
	local self_buffs, party_buffs = get_missing_buffs()
	local missing_buffs = merge_tables(self_buffs, party_buffs)
	if next(missing_buffs) == nil then
		print("You miss no buffs. Everything is fine, hooray!")
	else
		print("Missing buffs: " .. concat_bufflinks(missing_buffs))
	end
end

local function ask_for_buffs_for_party()
	local members = get_party_members()
	local classes = get_classes(members)
	local everything_ok = true
	for player, _ in pairs(members) do
		local missing_self_buffs, missing_party_buffs = get_missing_buffs(player, classes)
		local missing_buffs = merge_tables(missing_self_buffs, missing_party_buffs)
		if next(missing_buffs) ~= nil then
			everything_ok = false
			local message = player .. " is missing " .. concat_bufflinks(missing_buffs)
			SendChatMessage(message, is_in_raid and "RAID" or "PARTY")
		end
	end
	if everything_ok then
		print("Everything is ok. Nobody is missing anything.")
	end
end

local function check_party_buffs()
	local members = get_party_members()
	local classes = get_classes(members)
	local everything_ok = true
	for player, _ in pairs(members) do
		local missing_self_buffs, missing_party_buffs = get_missing_buffs(player, classes)
		local missing_buffs = merge_tables(missing_self_buffs, missing_party_buffs)
		if next(missing_buffs) ~= nil then
			everything_ok = false
			print(player .. " is missing " .. concat_bufflinks(missing_buffs))
		end
	end
	if everything_ok then
		print("Everything is ok. Nobody is missing anything.")
	end
end

function GimmeBuffsPlsAddonCheckParty(include_player)
	local player = UnitName("player")
	local members = get_party_members()
	local classes = get_classes(members)
	local lines = {}
	for member, _ in pairs(members) do
		if not include_player and player ~= member then
			local missing_self_buffs, missing_party_buffs = get_missing_buffs(member, classes)
			local missingBuffs = merge_tables(missing_self_buffs, missing_party_buffs)
			if next(missingBuffs) ~= nil then
				table.insert(lines, member .. ": " .. concat(get_keys(missingBuffs), ", "))
			end
		end
	end
	return table.concat(lines, "\n")
end

function GimmeBuffsPlsAddonCheckPlayer()
	local lines = {}
	local missingBuffs = merge_tables(get_missing_buffs())
	for buff, _ in pairs(missingBuffs) do
		table.insert(lines, "Missing " .. buff)
	end
	return table.concat(lines, "\n")
end

function GimmeBuffsPls_CheckParty(include_player)
	return GimmeBuffsPlsAddonCheckParty(include_player)
end

function GimmeBuffsPls_CheckMe()
	return GimmeBuffsPlsAddonCheckPlayer()
end

SLASH_GIMMEBUFFSPLS1 = "/buff"
-- SLASH_GIMMEBUFFSPLS2 = "/x"
SlashCmdList["GIMMEBUFFSPLS"] = function(command)
	local original_message = SLASH_GIMMEBUFFSPLS1 .. " " .. command
	print(original_message)
	if command == "me" then
		ask_for_buffs()
	elseif command == "party" then
		ask_for_buffs_for_party()
	elseif command == "check" then
		check_party_buffs()
	elseif command == "check me" then
		check_self_buffs()
	else
		print("ERROR: Unsupported command: " .. original_message)
	end
end
