--[[
## Interface: 30300
## Title: GimmeBuffsPls
## Version: 0.0.1
## Notes: /buff
## Author: Me
]]

local AddonName = "GimmeBuffsPls"

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

local function getPartyMembers()
	local members = {}
	local player = UnitName("player")
	local partyType = IsInRaid() and "raid" or "party"
	members[player] = string.lower(select(2, UnitClass("player")))
	for i = 1, GetNumGroupMembers() do
		local name = UnitName(partyType .. i)
		if name ~= player then
			members[name] = string.lower(select(2, UnitClass(partyType .. i)))
		end
	end
	return members
end

local function getClasses(members)
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
		deathknight = 0
	}
	for _, class in pairs(members) do
		classes[class] = classes[class] + 1
	end
	return classes
end

local function getMissingBuffs(player, members)
	local missingSelfBuffs = {}
	local missingPartyBuffs = {}
	local classes = getClasses(members)
	local class = string.lower(select(2, UnitClass(player)))

	-- Party buffs
	local function check(spell_id, spell_names)
		for _, spell_name in ipairs(spell_names) do
			if UnitBuff(player, spell_name) ~= nil then
				return true
			end
		end
		missingPartyBuffs[spell_names[1]] = spell_id
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
	if classes.warlock > 0 then
		-- check(57567, { "Fel Intelligence" })
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
		missingPartyBuffs[spell_names[1]] = nil
		missingSelfBuffs[spell_names[1]] = spell_id
		return false
	end

	if class == "mage" then
		-- check(42995, { "Arcane Intellect", "Arcane Brilliance" })
		check(42995, { "Arcane Intellect", "Arcane Brilliance", "Dalaran Brilliance" })
		check(43046, { "Molten Armor", "Ice Armor" })
	elseif class == "druid" then
		check(48469, { "Mark of the Wild", "Gift of the Wild" })
	elseif class == "priest" then
		-- check(10938, { "Power Word: Fortitude", "Prayer of Fortitude" })
		check(48161, { "Power Word: Fortitude", "Prayer of Fortitude" })
		check(48073, { "Divine Spirit", "Prayer of Spirit" })
		-- elseif class == "warlock" then
		-- check(57567, { "Fel Intelligence" })
	elseif class == "paladin" then
		check(20217, {
			"Blessing of Kings", "Greater Blessing of Kings", "Blessing of Wisdom", "Greater Blessing of Wisdom",
			"Blessing of Salvation", "Greater Blessing of Salvation", "Blessing of Sanctuary"
		})
	end
	return missingSelfBuffs, missingPartyBuffs
end

local function reportMissingBuffsOnTeamates()
	local members = getPartyMembers()
	local chatType = IsInRaid() and "RAID" or "PARTY"
	for player, _ in pairs(members) do
		local missingBuffs, missingPartyBuffs = getMissingBuffs(player, members)
		for key, value in pairs(missingPartyBuffs) do
			missingBuffs[key] = value
		end
		if next(missingBuffs) ~= nil then
			local message = player .. " is missing "
			for _, spell_id in pairs(missingBuffs) do
				message = message .. GetSpellLink(spell_id)
			end
			-- print(message)
			SendChatMessage(message, chatType)
			-- SendChatMessage(message)
		end
	end
end

local function reportMissingBuffsOnTeamatesToMe()
	local members = getPartyMembers()
	local chatType = IsInRaid() and "RAID" or "PARTY"
	for player, _ in pairs(members) do
		local missingBuffs, missingPartyBuffs = getMissingBuffs(player, members)
		for key, value in pairs(missingPartyBuffs) do
			missingBuffs[key] = value
		end
		if next(missingBuffs) ~= nil then
			local message = player .. " is missing "
			for _, spell_id in pairs(missingBuffs) do
				message = message .. GetSpellLink(spell_id)
			end
			print(message)
			-- SendChatMessage(message, chatType)
			-- SendChatMessage(message)
		end
	end
end

local function AskForBuffs()
	local members = getPartyMembers()
	local _, missingPartyBuffs = getMissingBuffs(UnitName("player"), members)
	if #missingPartyBuffs > 0 then
		local message = "Gimme "
		for _, spell_id in pairs(missingPartyBuffs) do
			message = message .. GetSpellLink(spell_id)
		end
		message = message .. " pls"
		SendChatMessage(message, chatType)
	end
end

local function partyClasses()
	local player_name = UnitName("player")
	local partyType = IsInRaid() and "raid" or "party"
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
	classes[string.lower(select(2, UnitClass("player")))] = 1
	for i = 1, GetNumGroupMembers() do
		if UnitName(partyType .. i) ~= player_name then
			local class = string.lower(select(2, UnitClass(partyType .. i)))
			classes[class] = classes[class] + 1
		end
	end
	return classes
end


local function countPeople()
	local paladins = 0
	local mages = 0
	local i = 1
	local n = GetNumGroupMembers() + 1
	while i <= n do
		_, class = UnitClass("raid" .. i)
		if class == nil then
			_, class = UnitClass("party" .. i)
		end
		print("party" .. i, " = ", class, UnitName("party" .. i))
		if class == "PALADIN" then
			paladins = paladins + 1
		end
		if class == "MAGE" then
			mages = mages + 1
		end
		i = i + 1
	end
	return mages, paladins
end

local expectedBuffs = {
	mage = {
		{ 42995, { "Arcane Intellect", "Arcane Brilliance", "Dalaran Brilliance" } },
		{ 54646, { "Focus Magic" } },
	},
	priest = {
		{ 21562, { "Prayer of Fortitude" } },
	},
	paladin = {
		{ 20217, { "Blessing of Kings", "Greater Blessing of Kings" } }
	},
}

local function checkPartyBuffs()
	local missingBuffs = {}
	local mages, paladins = countPeople()
	print("mages=" .. mages .. ", paladins=" .. paladins)
	if mages >= 1 and UnitBuff("player", "Arcane Intellect") == nil then
		missingBuffs["Arcane Intellect"] = 42995
	end
	if mages >= 2 and UnitBuff("player", "Focus Magic") == nil then
		missingBuffs["Focus Magic"] = 54646
	end
	if paladins >= 1 and UnitBuff("player", "Blessing of Kings") == nil and UnitBuff("player", "Greater Blessing of Kings") == nil then
		missingBuffs["Blessing of Kings"] = 20217
	end
	if paladins >= 2 and UnitBuff("player", "Blessing of Wisdom") == nil then
		missingBuffs["Blessing of Wisdom"] = 48936
	end
	return missingBuffs
end


local function getMissingPartyBuffsFormatted()
	local text = ""
	local buffs = checkPartyBuffs()
	for name, _ in pairs(buffs) do
		if text ~= "" then
			text = text .. "\n"
		end
		text = text .. "Missing " .. name
	end
	return text
end

SLASH_GIMMEBUFFSPLS1 = "/buff"
-- SLASH_GIMMEBUFFSPLS2 = "/x"
SlashCmdList["GIMMEBUFFSPLS"] = function(command)
	print("Command: " .. command)
	if command == "ask" then
		AskForBuffs()
	elseif command == "report" then
		reportMissingBuffsOnTeamates()
	elseif command == "team" then
		reportMissingBuffsOnTeamatesToMe()
	else
		print(getMissingPartyBuffsFormatted())
		print(dump(partyClasses()))
	end
end
