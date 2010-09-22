DCRT = LibStub("AceAddon-3.0") : NewAddon("DCRT","AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

DCRT.Version = "2.0 20090914"

--[[For new version of dwdkp]]
MerDKP_Table = {}
--[[Local varible]]

local _G = getfenv(0)

local addon = DCRT

local DATE_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
local DATE_FORMAT = "%y-%m-%d"
local TIME_FORMAT = "%H:%M:%S"

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("DCRT", true)
local deformat = LibStub("Deformat-2.0")

local selectedRaid = nil
local currentRaid = nil
local currentTimer = nil
local selectedEvent = nil
local selectedItem = nil

local GetDungeonDifficulty = GetDungeonDifficulty or GetCurrentDungeonDifficulty


local DKPStringFormat = {
	["name"] = {
		["midkp"] = "MiDKP",
		["eqdkp"] = "EQDkp"
	},
	["function"] = {
		["midkp"] = function(raid)
			local xml = ""
			if raid then
				xml = "<midkp>"
				xml = xml .. "<raid>"
				xml = xml .. "<name>"
				xml = xml .. date("%Y.%m.%d %H:%M", raid["creationTime"]) .. " " .. L[raid["raidName"]]
				xml = xml .. "</name>"
				xml = xml .. "<version>" .. addon.Version .. "</version>"
				xml = xml .. "<start>" .. date("%Y.%m.%d %H:%M", raid["startTime"]) .. "</start>"
				xml = xml .. "<end>" .. date("%Y.%m.%d %H:%M", raid["finishTime"]) .. "</end>"
				xml = xml .. "<creator>" .. UnitName("player") .. "</creator>"
				xml = xml .. "<places>"
				xml = xml .. "<place>" .. L[raid["raidName"]] .. "</place>"
				xml = xml .. "</places>"
				xml = xml .. "<members>"
				for name, member in pairs(raid["members"]) do
					xml = xml .. "<member>"
					xml = xml .. "<name>" .. name .. "</name>"
					xml = xml .. "<class>" .. member["class"] .. "</class>"
					xml = xml .. "</member>"
				end
				xml = xml .. "</members>"
				if #raid["events"] > 0 then
					xml = xml .. "<events>"
					for _, event in ipairs(raid["events"]) do
						if #event["members"] ~= 0 then
							xml = xml .. "<event>"
							xml = xml .. "<name>" .. event["name"] .. "</name>"
							if event["boss"] then
								xml = xml .. "<boss>" .. event["name"] .. "</boss>"
							end
							xml = xml .. "<time>" .. date("%Y.%m.%d %H:%M", event["time"]) .. "</time>" 
							xml = xml .. "<members>"
							for _, member in ipairs(event["members"]) do
								xml = xml .. "<member>" .. member .. "</member>"
							end
							xml = xml .. "</members>"
							xml = xml .. "<point>" .. event["dkp"] .. "</point>"
							if event["dkp"] < 0 then
								xml = xml .. "<punish>true</punish>"
							end
							xml = xml .. "</event>"
						end
						if event["hasAlternate"] then
							if #event["alternates"] ~= 0 then
								xml = xml .. "<event>"
								xml = xml .. "<name>" .. event["name"] .. L["alternate"] .. "</name>"
								if event["boss"] then
									xml = xml .. "<boss>" .. event["name"] .. "</boss>"
								end
								xml = xml .. "<time>" .. date("%Y.%m.%d %H:%M", event["time"]) .. "</time>" 
								xml = xml .. "<members>"
								for _, member in ipairs(event["alternates"]) do
									xml = xml .. "<member>" .. member .. "</member>"
								end
								xml = xml .. "</members>"
								xml = xml .. "<point>" .. event["alternateDkp"] .. "</point>"
								xml = xml .. "</event>"
							end
						end
					end
					xml = xml .. "</events>"
				end
				if #raid["loots"] > 0 then
					xml = xml .. "<items>"
					for _, item in ipairs(raid["loots"]) do
						if not item["cancel"] then
							local _, link = GetItemInfo(item["id"])
							if not link then
								GameTooltip:SetHyperlink("item:" .. item["id"])
								_, link = GetItemInfo(item["id"])
							end
							xml = xml .. "<item>"
							xml = xml .. "<name>" .. link:replace("|", "$") .. "</name>"
							xml = xml .. "<time>" .. date("%Y.%m.%d %H:%M", item["time"]) .. "</time>"
							xml = xml .. "<looter>" .. item["member"] .. "</looter>"
							xml = xml .. "<point>" .. item["dkp"] .. "</point>"
							xml = xml .. "</item>"
						end
					end
					xml = xml .. "</items>"
				end
				xml = xml .. "</raid>"
				xml = xml .. "</midkp>"
			end
			addon.db.profile.xml = xml
			return xml
		end,
		["eqdkp"] = function(raid)
			local xml = ""
			if raid then
				xml = "<RaidInfo>"
				xml = xml .. "<key>" .. date("%m/%d/%y %H:%M:%S", raid["creationTime"]) .. "</key>"
				xml = xml .. "<realm>" .. GetRealmName() .. "</realm>"
				xml = xml .. "<start>" .. date("%m/%d/%y %H:%M:%S", raid["startTime"]) .. "</start>"
				xml = xml .. "<end>" .. date("%m/%d/%y %H:%M:%S", raid["finishTime"]) .. "</end>"
				xml = xml .. "<difficulty>" .. GetDungeonDifficulty() .. "</difficulty>"
				xml = xml .. "<PlayerInfos>"
				local key = 1
				for name, member in pairs(raid["members"]) do
					xml = xml .. "<key" .. key .. ">"
					xml = xml .. "<name>" .. name .. "</name>"
					if member["race"] then
						xml = xml .. "<race>" .. member["race"] .. "</race>"
					end
					xml = xml .. "<sex>" .. member["sex"] .. "</sex>"
					xml = xml .. "<class>" .. member["class"] .. "</class>"
					xml = xml .. "<level>" .. member["level"] .. "</level>"
					xml = xml .. "</key" .. key ..">"
					key = key + 1
				end
				xml = xml .. "</PlayerInfos>"
				xml = xml .. "<BossKills>"
				key = 1
				for _, event in ipairs(raid["events"]) do
					xml = xml .. "<key" .. key .. ">"
					xml = xml .. "<name>" .. event["name"] .. "</name>"
					xml = xml .. "<dkp>" .. event["dkp"] .. "</dkp>"
					xml = xml .. "<time>" .. date("%m/%d/%y %H:%M:%S", event["time"]) .. "</time>"
					xml = xml .. "<attendees>"
					local k = 1
					for _, member in ipairs(event["members"]) do
						xml = xml .. "<key" .. k .. ">"
						xml = xml .. "<name>" .. member .. "</name>"
						xml = xml .. "</key" .. k ..">"
						k = k + 1
					end
					xml = xml .. "</attendees>"
					xml = xml .. "</key" .. key ..">"
					key = key + 1
					k = k + 1
					if event["hasAlternate"] then
						xml = xml .. "<key" .. key .. ">"
						xml = xml .. "<name>" .. event["name"] .. L["alternate"] .. "</name>"
						xml = xml .. "<dkp>" .. event["alternateDkp"] .. "</dkp>"
						xml = xml .. "<time>" .. date("%m/%d/%y %H:%M:%S", event["time"]) .. "</time>"
						xml = xml .. "<attendees>"
						k = 1
						for _, member in ipairs(event["alternates"]) do
							xml = xml .. "<key" .. k .. ">"
							xml = xml .. "<name>" .. member .. "</name>"
							xml = xml .. "</key" .. k ..">"
							k = k + 1
						end
						xml = xml .. "</attendees>"
						xml = xml .. "</key" .. key ..">"
						key = key + 1
					end
				end
				xml = xml .. "</BossKills>"
				xml = xml .. "<note><![CDATA[   ]]></note>"
				xml = xml .. "<Loot>"
				key = 1
				local itemColorTable = {
					[0] = "ff9d9d9d",
					[1] = "ffffffff",
					[2] = "ff1eff00",
					[3] = "ff0070dd",
					[4] = "ffa335ee",
					[5] = "ffff8000",
					[6] = "ffe6cc80",
				}
				for _, item in pairs(raid["loots"]) do
					if not item["resolve"] and not item["storage"] and not item["cancel"] then
						local name, link, quality, _, _, type, subtype, _, _, icon = GetItemInfo(item["id"])
						if not link then
							GameTooltip:SetHyperlink("item:" .. item["id"])
							_, link = GetItemInfo(item["id"])
						end
						xml = xml .. "<key" .. key ..">"
						xml = xml .. "<ItemName>" .. name .. "</ItemName>"
						xml = xml .. "<ItemID>" .. item["id"] .. "</ItemID>"
						if icon then xml = xml .. "<Icon>" .. icon .. "</Icon>" end
						if type then xml = xml .. "<Class>" .. type .. "</Class>" end
						if subtype then xml = xml .. "<SubClass>" .. subtype .. "</SubClass>" end
						if quality then xml = xml .. "<Color>" .. itemColorTable[quality] .. "</Color>" end
						xml = xml .. "<Count>" .. 1 .. "</Count>"
						xml = xml .. "<Player>" .. item["member"] .. "</Player>"
						xml = xml .. "<Time>" .. date("%m/%d/%y %H:%M:%S", item["time"]) .. "</Time>"
						xml = xml .. "<Zone>" .. raid["raidName"] .. "</Zone>"
						xml = xml .. "<Difficulty>" .. GetDungeonDifficulty() .. "</Difficulty>"
						xml = xml .. "<Costs>" .. item["dkp"] .. "</Costs>"
						xml = xml .. "</key" .. key .. ">"
						key = key + 1
					end
				end
				xml = xml .. "</Loot>"
				xml = xml .. "</RaidInfo>"
			end
			return xml
		end
	}
}

local DKPDataFormat = {
	["name"] = {
		["midkp"] = "MiDKP",
		["merdkp"] = "MerDKP"
	},
	["function"] = {
		["midkp"] = function()
			if MiDKPData and MiDKPData["dkp"] then
				local sum = 0.0
				for i, dkpSystem in ipairs(MiDKPData["dkp"]) do
					for name, member in pairs(dkpSystem["members"]) do
						sum = sum + member["score"]
					end
				end
				if sum ~= addon.db.profile["dkp"]["sum"] then
					for i, dkpSystem in ipairs(MiDKPData["dkp"]) do
						if not addon.db.profile["dkp"]["list"][dkpSystem["name"]] then
							addon.db.profile["dkp"]["list"][dkpSystem["name"]] = {}
							addon.db.profile["dkp"]["list"][dkpSystem["name"]]["title"] = dkpSystem["name"]
							addon.db.profile["dkp"]["list"][dkpSystem["name"]]["whisper"] = tostring(i)
						end
						local dkp = addon.db.profile["dkp"]["list"][dkpSystem["name"]]
						dkp["data"] = {}
						for name, member in pairs(dkpSystem["members"]) do
							dkp["data"][name] = {}
							dkp["data"][name]["dkp"] = member["score"]
							dkp["data"][name]["class"] = member["class"]
						end
					end
					for k, v in pairs(addon.db.profile["dkp"]["list"]) do
						local exists = false
						for _, d in pairs(MiDKPData["dkp"]) do
							if d["title"] == v["name"] then
								exists = true
							end
						end
						if not exists then
							addon.db.profile["dkp"]["list"][k] = nil
						end
					end
					addon:PrintMessage("pormpt", L["Dkp data update succeed"])
					addon.db.profile["dkp"]["sum"] = sum
				end
			else
				addon:PrintMessage("error", L["Cannot find dkp data"])
			end
		end,
		["merdkp"] = function()
			if Mer_DKP_Table then
				for i ,key in ipairs(Mer_DKP_NumTable) do
					MerDKP_Table[i] = Mer_DKP_Table[key]
					MerDKP_Table[i]["title"] = key
					MerDKP_Table[i]["whisper"] = tostring(i)
				end
			end
			local sum = 0
			for i, v in ipairs(MerDKP_Table) do
				for _, member in ipairs(v) do
					sum = sum + member["dkp"]
				end
			end
			if sum ~= addon.db.profile["dkp"]["sum"] then
				for i, v in ipairs(MerDKP_Table) do
					if not addon.db.profile["dkp"]["list"][v["title"]] then
						addon.db.profile["dkp"]["list"][v["title"]] = {}
						addon.db.profile["dkp"]["list"][v["title"]]["title"] = v["title"]
						addon.db.profile["dkp"]["list"][v["title"]]["whisper"] = v["whisper"]
					end
					local dkp = addon.db.profile["dkp"]["list"][v["title"]]
					dkp["data"] = {}
					for _, p in ipairs(v) do
						dkp["data"][p["name"]] = {}
						local d = dkp["data"][p["name"]]
						d["dkp"] = p["dkp"]
						if p["class"] == L["WARRIOR"] then
							d["class"] = "WARRIOR"
						elseif p["class"] == L["PALADIN"] then
							d["class"] = "PALADIN"
						elseif p["class"] == L["DEATHKNIGHT"] then
							d["class"] = "DEATHKNIGHT"
						elseif p["class"] == L["HUNTER"] then
							d["class"] = "HUNTER"
						elseif p["class"] == L["SHAMAN"] then
							d["class"] = "SHAMAN"
						elseif p["class"] == L["ROGUE"] then
							d["class"] = "ROGUE"
						elseif p["class"] == L["DRUID"] then
							d["class"] = "DRUID"
						elseif p["class"] == L["MAGE"] then
							d["class"] = "MAGE"
						elseif p["class"] == L["WARLOCK"] then
							d["class"] = "WARLOCK"
						elseif p["class"] == L["PRIEST"] then
							d["class"] = "PRIEST"
						end
					end
				end
				for k, v in pairs(addon.db.profile["dkp"]["list"]) do
					local exists = false
					for _, d in pairs(MerDKP_Table) do
						if d["title"] == v["title"] then
							exists = true
						end
					end
					if not exists then
						addon.db.profile["dkp"]["list"][k] = nil
					end
				end
				addon:PrintMessage("pormpt", L["Dkp data update succeed"])
				addon.db.profile["dkp"]["sum"] = sum
			elseif #MerDKP_Table == 0 then
				addon:PrintMessage("error", L["Cannot find dkp data"])
			end
		end
	}
}

local defaultConfigs = {
	["iconPosition"] = 200,
	["raidConfigs"] = {
	--[[	["Serpentshrine Cavern"] = {
			["name"] = L["Serpentshrine Cavern"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["The Eye"] = {
			["name"] = L["The Eye"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Hyjal Summit"] = {
			["name"] = L["Hyjal Summit"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Black Temple"] = {
			["name"] = L["Black Temple"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Sunwell Plateau"] = {
			["name"] = L["Sunwell Plateau"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 6,
			["alternateScore"] = 3,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},]]
		["Ulduar"] = {
			["name"] = L["Ulduar"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Trial of the Crusader"] = {
			["name"] = L["Trial of the Crusader"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Vault of Archavon"] = {
			["name"] = L["Vault of Archavon"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Naxxramas"] = {
			["name"] = L["Naxxramas"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
		["Onyxia's Lair"] = {
			["name"] = L["Onyxia's Lair"],
			["mainParties"] = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["alternateParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = true,
				[7] = true,
				[8] = true
			},
			["banedParties"] = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false
			},
			["musterScore"] = 2,
			["bossScore"] = 3,
			["alternateScore"] = 1.5,
			["dismissScore"] = 2,
			["timeScore"] = 1,
			["alternateTimeScore"] = 1,
			["recordItemLevel"] = 4,
			["ignoredBoss"] = {
			}
		},
	},
	["raidList"] = {},
	["items"] = {
		--[[宝石]]
		[32227] = {
			["ignore"] = true
		},
		[32228] = {
			["ignore"] = true
		},
		[32249] = {
			["ignore"] = true
		},
		[32231] = {
			["ignore"] = true
		},
		[32230] = {
			["ignore"] = true
		},
		[32229] = {
			["ignore"] = true
		},
		[29434] = {
			["ignore"] = true
		},
		[34664] = {
			["ignore"] = true
		},
		[22450] = {
			["ignore"] = true
		},
		--[[凯尔萨斯七武器]]
		[30312] = {
			["ignore"] = true
		},
		[30311] = {
			["ignore"] = true
		},
		[30317] = {
			["ignore"] = true
		},
		[30316] = {
			["ignore"] = true
		},
		[30313] = {
			["ignore"] = true
		},
		[30314] = {
			["ignore"] = true
		},
		[30318] = {
			["ignore"] = true
		},
		[30319] = {
			["ignore"] = true
		},
		[30320] = {
			["ignore"] = true
		},
		--[[徽章, 水晶]]
		[47241] = {
			["ignore"] = true
		},
		[45624] = {
			["ignore"] = true
		},
		[40753] = {
			["ignore"] = true
		},
		[40752] = {
			["ignore"] = true
		},
		[34057] = {
			["ignore"] = true
		},
	},
	["dkpStringFormat"] = "eqdkp",
	["dkpDataFormat"] = "midkp",
	["whisperQuery"] = {
		["enabled"] = true,
		["querySelfOnly"] = false,
		["fuzzyQuery"] = true
	},
	["announcement"] = {
		["enabled"] = true,
		["channels"] = {
			["GUILD"] = false,
			["RAID"] = true,
			["WHISPER"] = true
		}
	},
	["alternateOutofRaid"] = {
		["enabled"] = true,
		["command"] = "dcrt"
	},
	["eventsIncludeOffline"] = true,
	["promptLootDialog"] = true,
	["dkp"] = {
		["updateTime"] = 0,
		["sum"] = -1,
		["list"] = {}
	}
}

--[[Show item id]]
do
	local function hookTip(frame, ...)
		local set = frame:GetScript("OnTooltipSetItem")

		frame:SetScript("OnTooltipSetItem", function(self, ...)
			local _, itemLink = frame:GetItem()
			if itemLink then
				local itemId = tonumber(select(3, itemLink:find("item:(%d+):")))
				self:AddLine(format(L["Item ID：%s"], itemId))
			end
			if set then
				return set(self, ...)
			end
		end)
	end
	hookTip(GameTooltip)
	hookTip(ItemRefTooltip)
	hookTip(ShoppingTooltip1)
	hookTip(ShoppingTooltip2)
end

--[[Useful controls]]
local tablet = LibStub("Tablet-2.0", true)
local mainFrame
local iconFrame

--[[Local functions]]
function RaidConfigGroup_Selected(container, event)
	local raid = nil
	container:ResumeLayout()
	local raidListHeading = AceGUI:Create("Heading")
	raidListHeading:SetText(L["Select Raid Zone"])
	raidListHeading:SetFullWidth(true)
	container:AddChild(raidListHeading)
	local raidListDropdown = AceGUI:Create("Dropdown")
	local tmpList = {}
	for k, v in pairs(addon.db.profile.raidConfigs) do
		tmpList[k] = v["name"]
	end
	raidListDropdown:SetList(tmpList)
	container:AddChild(raidListDropdown)			

	local m_partyCheckBoxes = {}
	local a_partyCheckBoxes = {}
	local b_partyCheckBoxes = {}

	local function OnPartyChecked(widget, event, value)
		if raid then
			widget:SetValue(true)
			local type = widget:GetUserData("type")
			local no = widget:GetUserData("no")
			raid[type .. "Parties"][no] = true
			if type == "main" then
				raid["alternateParties"][no] = false
				raid["banedParties"][no] = false
				a_partyCheckBoxes[no]:SetValue(false)
				b_partyCheckBoxes[no]:SetValue(false)
			elseif type == "alternate" then
				raid["mainParties"][no] = false
				raid["banedParties"][no] = false
				m_partyCheckBoxes[no]:SetValue(false)
				b_partyCheckBoxes[no]:SetValue(false)
			elseif type == "baned" then
				raid["mainParties"][no] = false
				raid["alternateParties"][no] = false
				a_partyCheckBoxes[no]:SetValue(false)
				m_partyCheckBoxes[no]:SetValue(false)
			end
		end
	end
	local mainPartiesHeading = AceGUI:Create("Heading")
	mainPartiesHeading:SetText(L["Main parties"])
	mainPartiesHeading:SetFullWidth(true)
	container:AddChild(mainPartiesHeading)
	for i = 1, 8 do
		local cb = AceGUI:Create("CheckBox")
		cb:SetLabel(L["Party"] .. i)
		cb:SetWidth(75)
		cb:SetUserData("type", "main")
		cb:SetUserData("no", i)
		cb:SetCallback("OnValueChanged", OnPartyChecked)
		container:AddChild(cb)
		m_partyCheckBoxes[i] = cb
	end

	local alternatePartiesHeading = AceGUI:Create("Heading")
	alternatePartiesHeading:SetText(L["Alternate parties"])
	alternatePartiesHeading:SetFullWidth(true)
	container:AddChild(alternatePartiesHeading)
	for i = 1, 8 do
		local cb = AceGUI:Create("CheckBox")
		cb:SetLabel(L["Party"] .. i)
		cb:SetWidth(75)
		cb:SetUserData("type", "alternate")
		cb:SetUserData("no", i)
		cb:SetCallback("OnValueChanged", OnPartyChecked)
		container:AddChild(cb)
		a_partyCheckBoxes[i] = cb
	end

	local banedPartiesHeading = AceGUI:Create("Heading")
	banedPartiesHeading:SetText(L["Baned parties"])
	banedPartiesHeading:SetFullWidth(true)
	container:AddChild(banedPartiesHeading)
	for i = 1, 8 do
		local cb = AceGUI:Create("CheckBox")
		cb:SetLabel(L["Party"] .. i)
		cb:SetWidth(75)
		cb:SetUserData("type", "baned")
		cb:SetUserData("no", i)
		cb:SetCallback("OnValueChanged", OnPartyChecked)
		container:AddChild(cb)
		b_partyCheckBoxes[i] = cb
	end

	local recordItemLevelHeading = AceGUI:Create("Heading")
	recordItemLevelHeading:SetText(L["Recode item level"])
	recordItemLevelHeading:SetFullWidth(true)
	container:AddChild(recordItemLevelHeading)
	local itemLevel = {
		[0] = L["Poor"],
		[1] = L["Common"],
		[2] = L["Uncommon"],
		[3] = L["Rare"],
		[4] = L["Epic"],
		[5] = L["Legendary"],
		[6] = L["Artifact"]
	}
	local recordItemLevelSlider = AceGUI:Create("Slider")
	recordItemLevelSlider:SetFullWidth(true)
	recordItemLevelSlider:SetSliderValues(0, 6, 1)
	recordItemLevelSlider.lowtext:SetText(select(4, GetItemQualityColor(0)) .. itemLevel[0])
	recordItemLevelSlider.hightext:SetText(select(4, GetItemQualityColor(6)) .. itemLevel[6])
	recordItemLevelSlider:SetCallback("OnValueChanged", function(widget , event, value)
		if raid then
			raid["recordItemLevel"] = value
		end
	end)
	recordItemLevelSlider.editbox:SetScript("OnTextChanged", function(widget)
		local value = tonumber(widget:GetText())
		if value then
			widget:SetText(select(4, GetItemQualityColor(value)) .. itemLevel[value])
		end
	end)
	container:AddChild(recordItemLevelSlider)

	local function OnScoreChanged(widget, event, text)
		if raid then
			local score = tonumber(text)
			if score then
				raid[widget:GetUserData("type") .. "Score"] = score
			else
				widget:SetText(raid[widget:GetUserData("type") .. "Score"])
				addon:PrintMessage("error", L["Score must be number"])
			end
		end
	end

	local scoreHeading = AceGUI:Create("Heading")
	scoreHeading:SetText(L["Score config"])
	scoreHeading:SetFullWidth(true)
	container:AddChild(scoreHeading)
	local musterScoreEditBox = AceGUI:Create("EditBox")
	musterScoreEditBox:SetLabel(L["Muster Score"])
	musterScoreEditBox:SetWidth(100)
	musterScoreEditBox:SetText(nil)
	musterScoreEditBox:SetUserData("type", "muster")
	musterScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(musterScoreEditBox)
	local bossScoreEditBox = AceGUI:Create("EditBox")
	bossScoreEditBox:SetLabel(L["Boss Score"])
	bossScoreEditBox:SetWidth(100)
	bossScoreEditBox:SetText(nil)
	bossScoreEditBox:SetUserData("type", "boss")
	bossScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(bossScoreEditBox)
	local alternateScoreEditBox = AceGUI:Create("EditBox")
	alternateScoreEditBox:SetLabel(L["Alternate Score"])
	alternateScoreEditBox:SetWidth(100)
	alternateScoreEditBox:SetText(nil)
	alternateScoreEditBox:SetUserData("type", "alternate")
	alternateScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(alternateScoreEditBox)
	local dismissScoreEditBox = AceGUI:Create("EditBox")
	dismissScoreEditBox:SetLabel(L["Dismiss Score"])
	dismissScoreEditBox:SetWidth(100)
	dismissScoreEditBox:SetText(nil)
	dismissScoreEditBox:SetUserData("type", "dismiss")
	dismissScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(dismissScoreEditBox)
	local timeScoreEditBox = AceGUI:Create("EditBox")
	timeScoreEditBox:SetLabel(L["Time Score Per Hour"])
	timeScoreEditBox:SetWidth(100)
	timeScoreEditBox:SetText(nil)
	timeScoreEditBox:SetUserData("type", "time")
	timeScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(timeScoreEditBox)
	local alternateTimeScoreEditBox = AceGUI:Create("EditBox")
	alternateTimeScoreEditBox:SetLabel(L["Alternate Time Score Per Hour"])
	alternateTimeScoreEditBox:SetWidth(100)
	alternateTimeScoreEditBox:SetText(nil)
	alternateTimeScoreEditBox:SetUserData("type", "alternateTime")
	alternateTimeScoreEditBox:SetCallback("OnEnterPressed", OnScoreChanged)
	container:AddChild(alternateTimeScoreEditBox)

	raidListDropdown:SetCallback("OnValueChanged", function(widget, event, key)
		raid = addon.db.profile.raidConfigs[key]
		for k, v in pairs(raid["mainParties"]) do
			m_partyCheckBoxes[k]:SetValue(v)
		end
		for k, v in pairs(raid["alternateParties"]) do
			a_partyCheckBoxes[k]:SetValue(v)
		end
		for k, v in pairs(raid["banedParties"]) do
			b_partyCheckBoxes[k]:SetValue(v)
		end
		recordItemLevelSlider:SetValue(raid["recordItemLevel"])
		musterScoreEditBox:SetText(raid["musterScore"])
		bossScoreEditBox:SetText(raid["bossScore"])
		alternateScoreEditBox:SetText(raid["alternateScore"])
		dismissScoreEditBox:SetText(raid["dismissScore"])
		timeScoreEditBox:SetText(raid["timeScore"])
		alternateTimeScoreEditBox:SetText(raid["alternateTimeScore"])
	end)
end

function RaidGroup_Selected(container, event)
	container:PauseLayout()			
	mainFrame.raidList = AceGUI:Create("InlineGroup")
	mainFrame.raidList:SetTitle(L["Raid list"])
	mainFrame.raidList:PauseLayout()
	mainFrame.raidListScrollFrame = AceGUI:Create("ScrollFrame")
	mainFrame.raidListScrollFrame:SetLayout("List")
	mainFrame.raidList:AddChild(mainFrame.raidListScrollFrame)
	mainFrame.raidListScrollFrame:SetPoint("TOPLEFT")
	mainFrame.raidListScrollFrame:SetPoint("RIGHT")
	mainFrame.raidListScrollFrame:SetPoint("BOTTOM", 0, 30)
	mainFrame.newRaidButton = AceGUI:Create("Button")
	mainFrame.newRaidButton:SetText(L["New"])
	mainFrame.newRaidButton:SetWidth(75)
	mainFrame.raidList:AddChild(mainFrame.newRaidButton)
	mainFrame.newRaidButton:SetPoint("BOTTOMLEFT")
	addon:SetHelp(mainFrame.newRaidButton, L["Create new a raid"])
	
	mainFrame.newRaidButton:SetCallback("OnClick", function(widget, event, button)
		container:ReleaseChildren();
		container:PauseLayout();
		local newRaidNameDropdown = AceGUI:Create("Dropdown")
		local tmpList = {}
		for k, v in pairs(addon.db.profile["raidConfigs"]) do
			tmpList[k] = v["name"]
		end
		newRaidNameDropdown:SetList(tmpList)
		newRaidNameDropdown:SetLabel(L["Select raid zone"])
		container:AddChild(newRaidNameDropdown)
		newRaidNameDropdown:SetPoint("TOPLEFT", 180, -100)
		newRaidNameDropdown:SetWidth(250)
		
		newRaidNameDropdown:SetCallback("OnValueChanged", function(widget, event, value)
			newRaidNameDropdown:SetUserData("raidName", value)
		end)
		
		local newRaidDKPSystemDropdown = AceGUI:Create("Dropdown")
		local tmpList = {}
		tmpList["none"] = L["None"]
		for k, v in pairs(addon.db.profile["dkp"]["list"]) do
			tmpList[k] = v["title"]
		end
		newRaidDKPSystemDropdown:SetList(tmpList)
		newRaidDKPSystemDropdown:SetLabel(L["Select dkp system"])
		container:AddChild(newRaidDKPSystemDropdown)
		newRaidDKPSystemDropdown:SetPoint("TOPLEFT", newRaidNameDropdown.frame, "BOTTOMLEFT", 0, 0)
		newRaidDKPSystemDropdown:SetWidth(250)
		
		newRaidDKPSystemDropdown:SetCallback("OnValueChanged", function(widget, event, value)
			newRaidDKPSystemDropdown:SetUserData("dkpSystem", value)
		end)
		
		local createButton = AceGUI:Create("Button")
		createButton:SetText(L["Create"])
		container:AddChild(createButton)
		createButton:SetPoint("TOPLEFT", newRaidDKPSystemDropdown.frame, "BOTTOMLEFT", 0, -10)
		createButton:SetWidth(100)
		createButton:SetCallback("OnClick", function(widget, event)
			local raidName = newRaidNameDropdown:GetUserData("raidName")
			local dkpSystem = newRaidDKPSystemDropdown:GetUserData("dkpSystem")
			if not raidName then 
				addon:PrintMessage("error", L["Please select a raid"])
				return
			end
			if not dkpSystem then
				addon:PrintMessage("error", L["Please select a dkp system"])
				return
			end
			addon:NewRaid(raidName, dkpSystem)
			container:SelectTab("raids")
		end)
		
		local cancelButton = AceGUI:Create("Button")
		cancelButton:SetText(L["Cancel"])
		container:AddChild(cancelButton)
		cancelButton:SetPoint("TOPRIGHT", newRaidDKPSystemDropdown.frame, "BOTTOMRIGHT", 0, -10)
		cancelButton:SetWidth(100)
		cancelButton:SetCallback("OnClick", function(widget, event)
			container:SelectTab("raids")
		end)
	end)
	
	mainFrame.deleteRaidButton = AceGUI:Create("Button")
	mainFrame.deleteRaidButton:SetText(L["Delete"])
	mainFrame.deleteRaidButton:SetWidth(75)
	mainFrame.raidList:AddChild(mainFrame.deleteRaidButton)
	mainFrame.deleteRaidButton:SetPoint("BOTTOMRIGHT")
	addon:SetHelp(mainFrame.deleteRaidButton, L["Delect selected raid"])
	mainFrame.deleteRaidButton:SetCallback("OnClick", function(widget, event, button)
		if selectedRaid then
			_G.StaticPopupDialogs["DCRTDeleteRaidDialog"]["text"] = format(L["Are you sure to delte the %s recode?"], date(DATE_TIME_FORMAT, selectedRaid["creationTime"]) .. " " .. L[selectedRaid["raidName"]])
			_G.StaticPopup_Show("DCRTDeleteRaidDialog")
		end
	end)
	container:AddChild(mainFrame.raidList)
	mainFrame.raidList:SetWidth(180)
	mainFrame.raidList:SetPoint("TOPLEFT")
	mainFrame.raidList:SetPoint("BOTTOM")
	
	mainFrame.raidInfoTabGroup = AceGUI:Create("TabGroup")
	mainFrame.raidInfoTabGroup:SetWidth(470)
	mainFrame.raidInfoTabGroup:SetTabs({{
		text = L["Info"],
		value = "info"
	},{
		text = L["Events"],
		value = "events"
	},{
		text = L["Members"],
		value = "members"
	},{
		text = L["Items"],
		value = "items"
	}})
	mainFrame.raidInfoTabGroup:SetCallback("OnGroupSelected", RaidInfoGroup_Selected)
	container:AddChild(mainFrame.raidInfoTabGroup)
	mainFrame.raidInfoTabGroup:SetPoint("TOPLEFT", mainFrame.raidList.frame, "TOPRIGHT", 0, 0)
	mainFrame.raidInfoTabGroup:SetPoint("BOTTOMRIGHT")
	mainFrame.raidInfoTabGroup:SelectTab("info")
	addon:UpdateRaidList(selectedRaid)
end

function DKPGroup_Selected(container, event)
	container:PauseLayout()
	local dkpListPanel = AceGUI:Create("InlineGroup")
	dkpListPanel:SetWidth(350)
	dkpListPanel:SetLayout("Fill")
	container:AddChild(dkpListPanel)
	dkpListPanel:SetPoint("TOPLEFT")
	dkpListPanel:SetPoint("BOTTOM", 0, 40)
	dkpListPanel:SetTitle(L["DKP"])
	local dkpListSf = AceGUI:Create("ScrollFrame")
	dkpListSf:SetLayout("List")
	dkpListSf:SetFullWidth(true)
	dkpListPanel:AddChild(dkpListSf)
	local dkpData = nil
	local dkpSystem = nil

	local function OnDKPLabelClick(widget, event)
		local data = {}
		tinsert(data, widget:GetUserData("dkp"))
		local channel = nil
		if IsControlKeyDown() then
			channel = "RAID"
		elseif IsShiftKeyDown() then
			channel = "GUILD"
		else
			channel = "WHISPER"
		end
		addon:SendDKPMessage(dkpSystem["title"], data, channel, nil)
	end

	local function UpdateDKPList()
		dkpListSf:ReleaseChildren()
		if dkpData then
			for _, v in ipairs(dkpData) do
				local sg = AceGUI:Create("SimpleGroup")
				sg:SetFullWidth(true)
				sg:PauseLayout()
				local class = v["class"]
				local nameLabel = AceGUI:Create("InteractiveLabel")
				nameLabel:SetColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
				nameLabel:SetText(v["name"])
				nameLabel:SetWidth(130)
				nameLabel:SetHighlight(0.4,0.4,0.4,0.4)
				nameLabel:SetUserData("dkp", v)
				nameLabel:SetCallback("OnClick", OnDKPLabelClick)
				sg:AddChild(nameLabel)
				nameLabel:SetPoint("TOPLEFT")
				local classLabel = AceGUI:Create("InteractiveLabel")
				classLabel:SetColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
				classLabel:SetText(L[v["class"]])
				classLabel:SetWidth(120)
				classLabel:SetHighlight(0.4,0.4,0.4,0.4)
				classLabel:SetUserData("dkp", v)
				classLabel:SetCallback("OnClick", OnDKPLabelClick)
				sg:AddChild(classLabel)
				classLabel:SetPoint("TOPLEFT", nameLabel.frame, "TOPRIGHT", 0, 0)
				local dkpLabel = AceGUI:Create("InteractiveLabel")
				if v["dkp"] < 0 then
					dkpLabel:SetColor(1, 0, 0)
				end
				if v["dkp"] > 0 then
					dkpLabel:SetColor(0, 0.8, 0)
				end
				dkpLabel:SetText(v["dkp"])
				dkpLabel:SetWidth(70)
				dkpLabel:SetHighlight(0.4,0.4,0.4,0.4)
				dkpLabel:SetUserData("dkp", v)
				dkpLabel:SetCallback("OnClick", OnDKPLabelClick)
				sg:AddChild(dkpLabel)
				dkpLabel:SetPoint("TOPLEFT", classLabel.frame, "TOPRIGHT", 0, 0)
				sg:SetHeight(20)
				dkpListSf:AddChild(sg)
				local function showHighlight(widget, event)
					nameLabel.highlight:Show()
					classLabel.highlight:Show()
					dkpLabel.highlight:Show()
				end
				
				local function hideHighlight(widget, event)
					nameLabel.highlight:Hide()
					classLabel.highlight:Hide()
					dkpLabel.highlight:Hide()
				end
				nameLabel:SetCallback("OnEnter", showHighlight)
				nameLabel:SetCallback("OnLeave", hideHighlight)
				classLabel:SetCallback("OnEnter", showHighlight)
				classLabel:SetCallback("OnLeave", hideHighlight)
				dkpLabel:SetCallback("OnEnter", showHighlight)
				dkpLabel:SetCallback("OnLeave", hideHighlight)
				addon:SetHelp(nameLabel, L["Left click to send dkp by whisper, SHIFT + left click to send dkp to guild, CTRL + left click to send dkp to raid"])
				addon:SetHelp(classLabel, L["Left click to send dkp by whisper, SHIFT + left click to send dkp to guild, CTRL + left click to send dkp to raid"])
				addon:SetHelp(dkpLabel, L["Left click to send dkp by whisper, SHIFT + left click to send dkp to guild, CTRL + left click to send dkp to raid"])
			end
		end
	end

	local dkpSortButtons = {}

	local function OnDKPSortButtonClick(widget, event, value)
		if dkpData then
			for k, v in pairs(dkpSortButtons) do
				if widget:GetUserData("sort") == v:GetUserData("sort") then
					local attrib = widget:GetUserData("sort")
					if last == attrib then
						asc = not asc
					end
					sort(dkpData, function(a, b)
						if asc then
							return a[attrib] < b[attrib]
						else
							return a[attrib] > b[attrib]
						end
					end)
					last = attrib
				end
			end
			UpdateDKPList()
		end
	end
	local sortHeading = AceGUI:Create("Heading")
	sortHeading:SetText(L["Sort"])
	container:AddChild(sortHeading)
	sortHeading:SetPoint("TOPLEFT", dkpListPanel.frame, "BOTTOMLEFT")
	sortHeading:SetPoint("RIGHT", dkpListPanel.frame, "RIGHT")

	dkpSortButtons["name"] = AceGUI:Create("Button")
	dkpSortButtons["name"]:SetText(L["Name"])
	dkpSortButtons["name"]:SetWidth(100)
	dkpSortButtons["name"]:SetUserData("sort", "name")
	dkpSortButtons["name"]:SetUserData("asc", true)
	dkpSortButtons["name"]:SetCallback("OnClick", OnDKPSortButtonClick)
	container:AddChild(dkpSortButtons["name"])
	dkpSortButtons["name"]:SetPoint("TOPLEFT", sortHeading.frame, "BOTTOMLEFT")
	dkpSortButtons["class"] = AceGUI:Create("Button")
	dkpSortButtons["class"]:SetText(L["Class"])
	dkpSortButtons["class"]:SetWidth(100)
	dkpSortButtons["class"]:SetUserData("sort", "class")
	dkpSortButtons["class"]:SetUserData("asc", true)
	dkpSortButtons["class"]:SetCallback("OnClick", OnDKPSortButtonClick)
	container:AddChild(dkpSortButtons["class"])
	dkpSortButtons["class"]:SetPoint("TOP", sortHeading.frame, "BOTTOM")
	dkpSortButtons["class"]:SetPoint("CENTER", sortHeading.frame, "CENTER")
	dkpSortButtons["dkp"] = AceGUI:Create("Button")
	dkpSortButtons["dkp"]:SetText(L["DKP"])
	dkpSortButtons["dkp"]:SetWidth(100)
	dkpSortButtons["dkp"]:SetUserData("sort", "dkp")
	dkpSortButtons["dkp"]:SetUserData("asc", true)
	dkpSortButtons["dkp"]:SetCallback("OnClick", OnDKPSortButtonClick)
	container:AddChild(dkpSortButtons["dkp"])
	dkpSortButtons["dkp"]:SetPoint("TOPRIGHT", sortHeading.frame, "BOTTOMRIGHT")

	local dkpControlPanel = AceGUI:Create("InlineGroup")
	dkpControlPanel:SetTitle(L["Category"])
	dkpControlPanel:SetLayout("Flow")
	container:AddChild(dkpControlPanel)
	local dkpSystemListHeading = AceGUI:Create("Heading")
	dkpSystemListHeading:SetText(L["Select dkp system"])
	dkpSystemListHeading:SetFullWidth(true)
	dkpControlPanel:AddChild(dkpSystemListHeading)
	local dkpSystemDropdown = AceGUI:Create("Dropdown")
	dkpSystemDropdown:SetFullWidth(true)
	local tmpList = {}
	for _, v in pairs(addon.db.profile["dkp"]["list"]) do
		tmpList[v["title"]] = v["title"]
	end
	dkpSystemDropdown:SetList(tmpList)
	dkpControlPanel:AddChild(dkpSystemDropdown)
	local filter = {
		["inRaid"] = false,
		["class"] = {
			["WARRIOR"] = false,
			["PALADIN"] = false,
			["DEATHKNIGHT"] = false,
			["HUNTER"] = false,
			["SHAMAN"] = false,
			["ROGUE"] = false,
			["DRUID"] = false,
			["MAGE"] = false,
			["WARLOCK"] = false,
			["PRIEST"] = false
		},
	}
	local function UpdateDKPData()
		if dkpSystem then
			dkpData = {}
			for name, info in pairs(dkpSystem["data"]) do
				if filter["class"][info["class"]] then
					local inRaid = false
					if filter["inRaid"] then
						local num = GetNumRaidMembers()
						for i = 1, num do
							local n = GetRaidRosterInfo(i)
							if n == name then
								inRaid = true
								break
							end
						end
					end
					if (filter["inRaid"] and inRaid) or (not filter["inRaid"]) then
						tinsert(dkpData, {
							["name"] = name,
							["class"] = info["class"],
							["dkp"] = info["dkp"]
						})
					end
				end
			end
			UpdateDKPList()
		end
	end
	dkpSystemDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		dkpSystem = addon.db.profile["dkp"]["list"][value]
		UpdateDKPData()
	end)

	local inRaidCheckBox = AceGUI:Create("CheckBox")
	inRaidCheckBox:SetLabel(L["Show only in raid"])
	dkpControlPanel:AddChild(inRaidCheckBox)

	inRaidCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		filter["inRaid"] = value
		UpdateDKPData()
	end)
	local allClassCheckBox
	local function OnDKPClassChecked(widget, event, value)
		filter["class"][widget:GetUserData("class")] = value
		if not value then
			allClassCheckBox:SetValue(false)
		end
		UpdateDKPData()
	end
	local classHeading = AceGUI:Create("Heading")
	classHeading:SetText(L["Class"])
	classHeading:SetFullWidth(true)
	dkpControlPanel:AddChild(classHeading)
	local warriorCheckBox = AceGUI:Create("CheckBox")
	warriorCheckBox:SetLabel(L["WARRIOR"])
	warriorCheckBox:SetWidth(90)
	warriorCheckBox.text:SetTextColor(RAID_CLASS_COLORS["WARRIOR"].r, RAID_CLASS_COLORS["WARRIOR"].g, RAID_CLASS_COLORS["WARRIOR"].b)
	warriorCheckBox:SetUserData("class", "WARRIOR")
	warriorCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(warriorCheckBox)
	local paladinCheckBox = AceGUI:Create("CheckBox")
	paladinCheckBox:SetLabel(L["PALADIN"])
	paladinCheckBox:SetWidth(90)
	paladinCheckBox.text:SetTextColor(RAID_CLASS_COLORS["PALADIN"].r, RAID_CLASS_COLORS["PALADIN"].g, RAID_CLASS_COLORS["PALADIN"].b)
	paladinCheckBox:SetUserData("class", "PALADIN")
	paladinCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(paladinCheckBox)
	local deathKnightCheckBox = AceGUI:Create("CheckBox")
	deathKnightCheckBox:SetLabel(L["DEATHKNIGHT"])
	deathKnightCheckBox:SetWidth(90)
	deathKnightCheckBox.text:SetTextColor(RAID_CLASS_COLORS["DEATHKNIGHT"].r, RAID_CLASS_COLORS["DEATHKNIGHT"].g, RAID_CLASS_COLORS["DEATHKNIGHT"].b)
	deathKnightCheckBox:SetUserData("class", "DEATHKNIGHT")
	deathKnightCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(deathKnightCheckBox)
	local hunterCheckBox = AceGUI:Create("CheckBox")
	hunterCheckBox:SetLabel(L["HUNTER"])
	hunterCheckBox:SetWidth(90)
	hunterCheckBox.text:SetTextColor(RAID_CLASS_COLORS["HUNTER"].r, RAID_CLASS_COLORS["HUNTER"].g, RAID_CLASS_COLORS["HUNTER"].b)
	hunterCheckBox:SetUserData("class", "HUNTER")
	hunterCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(hunterCheckBox)
	local shamanCheckBox = AceGUI:Create("CheckBox")
	shamanCheckBox:SetLabel(L["SHAMAN"])
	shamanCheckBox:SetWidth(90)
	shamanCheckBox.text:SetTextColor(RAID_CLASS_COLORS["SHAMAN"].r, RAID_CLASS_COLORS["SHAMAN"].g, RAID_CLASS_COLORS["SHAMAN"].b)
	shamanCheckBox:SetUserData("class", "SHAMAN")
	shamanCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(shamanCheckBox)
	local rogueCheckBox = AceGUI:Create("CheckBox")
	rogueCheckBox:SetLabel(L["ROGUE"])
	rogueCheckBox:SetWidth(90)
	rogueCheckBox.text:SetTextColor(RAID_CLASS_COLORS["ROGUE"].r, RAID_CLASS_COLORS["ROGUE"].g, RAID_CLASS_COLORS["ROGUE"].b)
	rogueCheckBox:SetUserData("class", "ROGUE")
	rogueCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(rogueCheckBox)
	local druidCheckBox = AceGUI:Create("CheckBox")
	druidCheckBox:SetLabel(L["DRUID"])
	druidCheckBox:SetWidth(90)
	druidCheckBox.text:SetTextColor(RAID_CLASS_COLORS["DRUID"].r, RAID_CLASS_COLORS["DRUID"].g, RAID_CLASS_COLORS["DRUID"].b)
	druidCheckBox:SetUserData("class", "DRUID")
	druidCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(druidCheckBox)
	local mageCheckBox = AceGUI:Create("CheckBox")
	mageCheckBox:SetLabel(L["MAGE"])
	mageCheckBox:SetWidth(90)
	mageCheckBox.text:SetTextColor(RAID_CLASS_COLORS["MAGE"].r, RAID_CLASS_COLORS["MAGE"].g, RAID_CLASS_COLORS["MAGE"].b)
	mageCheckBox:SetUserData("class", "MAGE")
	mageCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(mageCheckBox)
	local warlockCheckBox = AceGUI:Create("CheckBox")
	warlockCheckBox:SetLabel(L["WARLOCK"])
	warlockCheckBox:SetWidth(90)
	warlockCheckBox.text:SetTextColor(RAID_CLASS_COLORS["WARLOCK"].r, RAID_CLASS_COLORS["WARLOCK"].g, RAID_CLASS_COLORS["WARLOCK"].b)
	warlockCheckBox:SetUserData("class", "WARLOCK")
	warlockCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(warlockCheckBox)
	local priestCheckBox = AceGUI:Create("CheckBox")
	priestCheckBox:SetLabel(L["PRIEST"])
	priestCheckBox:SetWidth(90)
	priestCheckBox.text:SetTextColor(RAID_CLASS_COLORS["PRIEST"].r, RAID_CLASS_COLORS["PRIEST"].g, RAID_CLASS_COLORS["PRIEST"].b)
	priestCheckBox:SetUserData("class", "PRIEST")
	priestCheckBox:SetCallback("OnValueChanged", OnDKPClassChecked)
	dkpControlPanel:AddChild(priestCheckBox)

	allClassCheckBox = AceGUI:Create("CheckBox")
	allClassCheckBox:SetLabel(L["All classes"])
	allClassCheckBox:SetWidth(90)
	dkpControlPanel:AddChild(allClassCheckBox)
	allClassCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		warriorCheckBox:SetValue(value)
		paladinCheckBox:SetValue(value)
		deathKnightCheckBox:SetValue(value)
		hunterCheckBox:SetValue(value)
		shamanCheckBox:SetValue(value)
		rogueCheckBox:SetValue(value)
		druidCheckBox:SetValue(value)
		mageCheckBox:SetValue(value)
		warlockCheckBox:SetValue(value)
		priestCheckBox:SetValue(value)
		for k, v in pairs(filter["class"]) do
			filter["class"][k] = value
		end
		UpdateDKPData()
	end)

	local armorHeading = AceGUI:Create("Heading")
	armorHeading:SetText(L["Armor"])
	armorHeading:SetFullWidth(true)
	dkpControlPanel:AddChild(armorHeading)
	local plateCheckBox = AceGUI:Create("CheckBox")
	plateCheckBox:SetLabel(L["Plate"])
	plateCheckBox:SetWidth(90)
	plateCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		warriorCheckBox:SetValue(value)
		paladinCheckBox:SetValue(value)
		deathKnightCheckBox:SetValue(value)
		filter["class"]["WARRIOR"] = value
		filter["class"]["PALADIN"] = value
		filter["class"]["DEATHKNIGHT"] = value
		UpdateDKPData()
	end)
	dkpControlPanel:AddChild(plateCheckBox)
	local mailCheckBox = AceGUI:Create("CheckBox")
	mailCheckBox:SetLabel(L["Mail"])
	mailCheckBox:SetWidth(90)
	mailCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		hunterCheckBox:SetValue(value)
		shamanCheckBox:SetValue(value)
		filter["class"]["HUNTER"] = value
		filter["class"]["SHAMAN"] = value
		UpdateDKPData()
	end)
	dkpControlPanel:AddChild(mailCheckBox)
	local leatherCheckBox = AceGUI:Create("CheckBox")
	leatherCheckBox:SetLabel(L["Leather"])
	leatherCheckBox:SetWidth(90)
	leatherCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		rogueCheckBox:SetValue(value)
		druidCheckBox:SetValue(value)
		filter["class"]["ROGUE"] = value
		filter["class"]["DRUID"] = value
		UpdateDKPData()
	end)
	dkpControlPanel:AddChild(leatherCheckBox)
	local clothCheckBox = AceGUI:Create("CheckBox")
	clothCheckBox:SetLabel(L["Cloth"])
	clothCheckBox:SetWidth(90)
	clothCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		mageCheckBox:SetValue(value)
		warlockCheckBox:SetValue(value)
		priestCheckBox:SetValue(value)
		filter["class"]["MAGE"] = value
		filter["class"]["WARLOCK"] = value
		filter["class"]["PRIEST"] = value
		UpdateDKPData()
	end)
	dkpControlPanel:AddChild(clothCheckBox)

	local optionHeading = AceGUI:Create("Heading")
	optionHeading:SetText(L["Send"])
	optionHeading:SetFullWidth(true)
	dkpControlPanel:AddChild(optionHeading)

	local sendChannelDropdown = AceGUI:Create("Dropdown")
	sendChannelDropdown:SetLabel(L["Channel"])
	sendChannelDropdown:SetList({
		["RAID"] = L["Raid"],
		["GUILD"] = L["Guild"],
		["WHISPER"] = L["Whisper"]
	})
	sendChannelDropdown:SetWidth(150)
	sendChannelDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		widget:SetUserData("channel", value)
	end)
	dkpControlPanel:AddChild(sendChannelDropdown)

	local sendButton = AceGUI:Create("Button")
	sendButton:SetText(L["Send"])
	sendButton:SetWidth(100)
	sendButton:SetCallback("OnClick", function(widget, event)
		local channel = sendChannelDropdown:GetUserData("channel")
		if dkpSystem then
			if channel then
				addon:SendDKPMessage(dkpSystem["title"], dkpData, channel)
			else
				addon:PrintMessage("error", L["Select a channel"])
			end
		else
			addon:PrintMessage("error", L["Please select a dkp system"])
		end
	end)
	dkpControlPanel:AddChild(sendButton)

	dkpControlPanel:SetPoint("TOPLEFT", dkpListPanel.frame, "TOPRIGHT", 0, 0)
	dkpControlPanel:SetPoint("BOTTOMRIGHT")

	if currentRaid and currentRaid["dkpSystem"] then
		inRaidCheckBox:SetValue(true)
		filter["inRaid"] = true
		dkpSystemDropdown:SetValue(currentRaid["dkpSystem"])
		dkpSystem = addon.db.profile["dkp"]["list"][currentRaid["dkpSystem"]]
		UpdateDKPData()
	end
end

function ItemGroup_Selected(container, event)
	container:PauseLayout()
	local itemScrollFrame = AceGUI:Create("ScrollFrame")
	container:AddChild(itemScrollFrame)
	itemScrollFrame:SetPoint("TOPLEFT")
	itemScrollFrame:SetPoint("BOTTOMRIGHT")
	itemScrollFrame:SetLayout("List")
	for id, item in pairs(addon.db.profile["items"]) do
		local sg = AceGUI:Create("SimpleGroup")
		local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(id)
		if not link then
			GameTooltip:SetHyperlink("item:" .. id)
			_, link, _, _, _, _, _, _, _, texture = GetItemInfo(id)
		end
		sg:PauseLayout()
		sg:SetFullWidth(true)
		sg:SetHeight(35)
		local itemIcon = AceGUI:Create("Icon")
		itemIcon:SetImageSize(32, 32)
		itemIcon:SetImage(texture)
		itemIcon:SetWidth(32)
		sg:AddChild(itemIcon)
		itemIcon:SetPoint("TOPLEFT")
		local nameLabel = AceGUI:Create("InteractiveLabel")
		nameLabel:SetText(link)
		sg:AddChild(nameLabel)
		nameLabel.label:SetJustifyV("CENTER")
		nameLabel:SetPoint("CENTER", itemIcon.frame, "CENTER")
		nameLabel:SetPoint("LEFT", itemIcon.frame, "RIGHT")
		nameLabel:SetCallback("OnEnter", function(widget, event)
			GameTooltip:SetOwner(nameLabel.frame, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end)
		nameLabel:SetCallback("OnLeave", function(widget, event)
			GameTooltip:Hide()
		end)
		itemScrollFrame:AddChild(sg)
		local ignoreCheckBox = AceGUI:Create("CheckBox")
		ignoreCheckBox:SetLabel(L["Ignore this item"])
		ignoreCheckBox:SetValue(item["ignore"])
		sg:AddChild(ignoreCheckBox)
		ignoreCheckBox:SetPoint("CENTER", itemIcon.frame, "CENTER")
		ignoreCheckBox:SetPoint("RIGHT")
		ignoreCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
			item["ignore"] = value
		end)
		addon:SetHelp(ignoreCheckBox, L["Pormpt dialog will not pop up after ignore this item."])
	end
end

function ConfigGroup_Selected(container, event)
	container:ResumeLayout()
	local whisperQueryHeading = AceGUI:Create("Heading")
	whisperQueryHeading:SetText(L["Whisper Query"])
	whisperQueryHeading:SetFullWidth(true)
	container:AddChild(whisperQueryHeading)
	local whisperQueryEnableCheckBox = AceGUI:Create("CheckBox")
	whisperQueryEnableCheckBox:SetLabel(L["Enable"])
	whisperQueryEnableCheckBox:SetWidth(100)
	whisperQueryEnableCheckBox:SetValue(addon.db.profile["whisperQuery"]["enabled"])
	container:AddChild(whisperQueryEnableCheckBox)
	local querySelfOnlyCheckBox = AceGUI:Create("CheckBox")
	querySelfOnlyCheckBox:SetLabel(L["Query self only"])
	querySelfOnlyCheckBox:SetWidth(200)
	querySelfOnlyCheckBox:SetValue(addon.db.profile["whisperQuery"]["querySelfOnly"])
	querySelfOnlyCheckBox:SetDisabled(not addon.db.profile["whisperQuery"]["enabled"])
	container:AddChild(querySelfOnlyCheckBox)
	local fuzzyQueryEnableCheckBox = AceGUI:Create("CheckBox")
	fuzzyQueryEnableCheckBox:SetLabel(L["Enable fuzzy query"])
	fuzzyQueryEnableCheckBox:SetWidth(150)
	fuzzyQueryEnableCheckBox:SetValue(addon.db.profile["whisperQuery"]["fuzzyQuery"])
	fuzzyQueryEnableCheckBox:SetDisabled(not addon.db.profile["whisperQuery"]["enabled"] or addon.db.profile["whisperQuery"]["querySelfOnly"])
	container:AddChild(fuzzyQueryEnableCheckBox)
	local dkpSystemListDropdown = AceGUI:Create("Dropdown")
	dkpSystemListDropdown:SetLabel(L["Whisper command"])
	dkpSystemListDropdown:SetDisabled(not addon.db.profile["whisperQuery"]["enabled"])
	local tmpList = {}
	for _, v in pairs(addon.db.profile["dkp"]["list"]) do
		tmpList[v["title"]] = v["title"]
	end
	dkpSystemListDropdown:SetList(tmpList)
	container:AddChild(dkpSystemListDropdown)
	local whisperCommandEditBox = AceGUI:Create("EditBox")
	whisperCommandEditBox:SetText(nil)
	whisperCommandEditBox:SetDisabled(not addon.db.profile["whisperQuery"]["enabled"])
	container:AddChild(whisperCommandEditBox)
	whisperQueryEnableCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["whisperQuery"]["enabled"] = value
		querySelfOnlyCheckBox:SetDisabled(not value)
		fuzzyQueryEnableCheckBox:SetDisabled(not value)
		dkpSystemListDropdown:SetDisabled(not value)
		whisperCommandEditBox:SetDisabled(not value)
	end)
	querySelfOnlyCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["whisperQuery"]["querySelfOnly"] = value
		fuzzyQueryEnableCheckBox:SetDisabled(value)
	end)
	fuzzyQueryEnableCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["whisperQuery"]["fuzzyQuery"] = value
	end)
	local dkpSystemListDropdownValue = nil
	dkpSystemListDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		whisperCommandEditBox:SetText(addon.db.profile["dkp"]["list"][value]["whisper"])
		dkpSystemListDropdownValue = value
	end)
	whisperCommandEditBox:SetCallback("OnEnterPressed", function(widget, event, text)
		if dkpSystemListDropdownValue then
			addon.db.profile["dkp"]["list"][dkpSystemListDropdownValue]["whisper"] = text
		end
	end)
	
	local announcementHeading = AceGUI:Create("Heading")
	announcementHeading:SetText(L["Events nnouncement"])
	announcementHeading:SetFullWidth(true)
	container:AddChild(announcementHeading)
	local announcementEnableCheckBox = AceGUI:Create("CheckBox")
	announcementEnableCheckBox:SetLabel(L["Enable"])
	announcementEnableCheckBox:SetFullWidth(true)
	announcementEnableCheckBox:SetValue(addon.db.profile["announcement"]["enabled"])
	container:AddChild(announcementEnableCheckBox)
	local announcementChannelLabel = AceGUI:Create("Label")
	announcementChannelLabel:SetText(L["Announcement chennels"])
	announcementChannelLabel:SetWidth(100)
	container:AddChild(announcementChannelLabel)
	local announcementGuildChannelCheckBox = AceGUI:Create("CheckBox")
	announcementGuildChannelCheckBox:SetLabel(L["Guild"])
	announcementGuildChannelCheckBox:SetWidth(100)
	announcementGuildChannelCheckBox:SetValue(addon.db.profile["announcement"]["channels"]["GUILD"])
	announcementGuildChannelCheckBox:SetUserData("channel", "GUILD")
	announcementGuildChannelCheckBox:SetDisabled(not addon.db.profile["announcement"]["enabled"])
	container:AddChild(announcementGuildChannelCheckBox)
	local announcementRaidChannelCheckBox = AceGUI:Create("CheckBox")
	announcementRaidChannelCheckBox:SetLabel(L["Raid"])
	announcementRaidChannelCheckBox:SetWidth(100)
	announcementRaidChannelCheckBox:SetValue(addon.db.profile["announcement"]["channels"]["RAID"])
	announcementRaidChannelCheckBox:SetUserData("channel", "RAID")
	announcementRaidChannelCheckBox:SetDisabled(not addon.db.profile["announcement"]["enabled"])
	container:AddChild(announcementRaidChannelCheckBox)
	local announcementWhisperChannelCheckBox = AceGUI:Create("CheckBox")
	announcementWhisperChannelCheckBox:SetLabel(L["Whisper"])
	announcementWhisperChannelCheckBox:SetWidth(100)
	announcementWhisperChannelCheckBox:SetValue(addon.db.profile["announcement"]["channels"]["WHISPER"])
	announcementWhisperChannelCheckBox:SetUserData("channel", "WHISPER")
	announcementWhisperChannelCheckBox:SetDisabled(not addon.db.profile["announcement"]["enabled"])
	container:AddChild(announcementWhisperChannelCheckBox)
	
	announcementEnableCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["announcement"]["enabled"] = value
		announcementGuildChannelCheckBox:SetDisabled(not value)
		announcementRaidChannelCheckBox:SetDisabled(not value)
		announcementWhisperChannelCheckBox:SetDisabled(not value)
	end)
	local function channelSelected(widget, event, value)
		addon.db.profile["announcement"]["channels"][widget:GetUserData("channel")] = value
	end
	announcementGuildChannelCheckBox:SetCallback("OnValueChanged", channelSelected)
	announcementRaidChannelCheckBox:SetCallback("OnValueChanged", channelSelected)
	announcementWhisperChannelCheckBox:SetCallback("OnValueChanged", channelSelected)
	
	local alternateOutofRaidHeading = AceGUI:Create("Heading")
	alternateOutofRaidHeading:SetText(L["Alternate out of raid"])
	alternateOutofRaidHeading:SetFullWidth(true)
	container:AddChild(alternateOutofRaidHeading)
	local alternateOutofRaidEnableCheckBox = AceGUI:Create("CheckBox")
	alternateOutofRaidEnableCheckBox:SetLabel(L["Enable"])
	alternateOutofRaidEnableCheckBox:SetValue(addon.db.profile["alternateOutofRaid"]["enabled"])
	container:AddChild(alternateOutofRaidEnableCheckBox)
	local alternateOutofRaidWhisperCommandEditBox = AceGUI:Create("EditBox")
	alternateOutofRaidWhisperCommandEditBox:SetLabel(L["Alternate out of raid whisper command"])
	alternateOutofRaidWhisperCommandEditBox:SetText(addon.db.profile["alternateOutofRaid"]["command"])
	alternateOutofRaidWhisperCommandEditBox:SetDisabled(not addon.db.profile["alternateOutofRaid"]["enabled"])
	container:AddChild(alternateOutofRaidWhisperCommandEditBox)
	
	alternateOutofRaidEnableCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["alternateOutofRaid"]["enabled"] = value
		alternateOutofRaidWhisperCommandEditBox:SetDisabled(not value)
	end)
	
	alternateOutofRaidWhisperCommandEditBox:SetCallback("OnEnterPressed", function(widget, event, text)
		addon.db.profile["alternateOutofRaid"]["command"] = text
	end)
		
	local importExportHeading = AceGUI:Create("Heading")
	importExportHeading:SetText(L["Import and export"])
	importExportHeading:SetFullWidth(true)
	container:AddChild(importExportHeading)
	local dkpStringFormatDropdown = AceGUI:Create("Dropdown")
	dkpStringFormatDropdown:SetLabel(L["DKP string format"])
	dkpStringFormatDropdown:SetList(DKPStringFormat["name"])
	dkpStringFormatDropdown:SetValue(addon.db.profile["dkpStringFormat"])
	container:AddChild(dkpStringFormatDropdown)
	dkpStringFormatDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["dkpStringFormat"] = value
	end)
	local dkpDataFormatDropdown = AceGUI:Create("Dropdown")
	dkpDataFormatDropdown:SetLabel(L["DKP data format"])
	dkpDataFormatDropdown:SetList(DKPDataFormat["name"])
	dkpDataFormatDropdown:SetValue(addon.db.profile["dkpDataFormat"])
	container:AddChild(dkpDataFormatDropdown)
	dkpDataFormatDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["dkpDataFormat"] = value
	end)
				
	local othersHeading = AceGUI:Create("Heading")
	othersHeading:SetText(L["Others"])
	othersHeading:SetFullWidth(true)
	container:AddChild(othersHeading)
	local includeOfflineCheckBox = AceGUI:Create("CheckBox")
	includeOfflineCheckBox:SetLabel(L["Include offline member while auto events occured"])
	includeOfflineCheckBox:SetFullWidth(true)
	includeOfflineCheckBox:SetValue(addon.db.profile["eventsIncludeOffline"])
	container:AddChild(includeOfflineCheckBox)
	includeOfflineCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["eventsIncludeOffline"] = value
	end)
	local promptLootDialogCheckBox = AceGUI:Create("CheckBox")
	promptLootDialogCheckBox:SetLabel(L["Pormpt to input dkp when a item is looted"])
	promptLootDialogCheckBox:SetFullWidth(true)
	promptLootDialogCheckBox:SetValue(addon.db.profile["promptLootDialog"])
	container:AddChild(promptLootDialogCheckBox)
	promptLootDialogCheckBox:SetCallback("OnValueChanged", function(widget, event, value)
		addon.db.profile["promptLootDialog"] = value
	end)
end

function MainTabGroup_TabChanged(container, event, group)
	container:ReleaseChildren()
	if group == "raids" then
		RaidGroup_Selected(container, event)
	elseif group == "items" then
		ItemGroup_Selected(container, event)
	elseif group == "raid config" then
		RaidConfigGroup_Selected(container, event)
	elseif group == "dkp" then
		DKPGroup_Selected(container, event)
	elseif group == "config" then
		ConfigGroup_Selected(container, event)
	end
end

function RaidInfoGroup_Selected(container, event, group)
	container:ReleaseChildren()
	container:SetUserData("group", group)
	if group == "info" then
		container:PauseLayout()
		local raidNameLabel = AceGUI:Create("Label")
		raidNameLabel:SetText(L["Raid Name"])
		container:AddChild(raidNameLabel)
		raidNameLabel:SetPoint("TOPLEFT", 80, -20)
		raidNameLabel:SetWidth(100)
		mainFrame.raidNameLabel = AceGUI:Create("Label")
		mainFrame.raidNameLabel:SetColor(0, 1, 0)
		container:AddChild(mainFrame.raidNameLabel)
		mainFrame.raidNameLabel:SetPoint("TOPLEFT", raidNameLabel.frame, "TOPRIGHT", 0, 0)
		local creationTimeLabel = AceGUI:Create("Label")
		creationTimeLabel:SetText(L["Create Time"])
		container:AddChild(creationTimeLabel)
		creationTimeLabel:SetPoint("TOPLEFT", raidNameLabel.frame, "BOTTOMLEFT", 0, -10)
		creationTimeLabel:SetWidth(100)
		mainFrame.creationTimeLabel = AceGUI:Create("Label")
		mainFrame.creationTimeLabel:SetColor(1, 0.5, 1)
		container:AddChild(mainFrame.creationTimeLabel)
		mainFrame.creationTimeLabel:SetPoint("TOPLEFT", creationTimeLabel.frame, "TOPRIGHT", 0, 0)
		local startTimeLabel = AceGUI:Create("Label")
		startTimeLabel:SetText(L["Start Time"])
		container:AddChild(startTimeLabel)
		startTimeLabel:SetWidth(100)
		startTimeLabel:SetPoint("TOPLEFT", creationTimeLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.startTimeLabel = AceGUI:Create("Label")
		mainFrame.startTimeLabel:SetColor(0, 0.5, 1)
		container:AddChild(mainFrame.startTimeLabel)
		mainFrame.startTimeLabel:SetPoint("TOPLEFT", startTimeLabel.frame, "TOPRIGHT", 0, 0)
		local finishTimeLabel = AceGUI:Create("Label")
		finishTimeLabel:SetText(L["Finish Time"])
		container:AddChild(finishTimeLabel)
		finishTimeLabel:SetWidth(100)
		finishTimeLabel:SetPoint("TOPLEFT", startTimeLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.finishTimeLabel = AceGUI:Create("Label")
		mainFrame.finishTimeLabel:SetColor(1, 0.5, 0)
		container:AddChild(mainFrame.finishTimeLabel)
		mainFrame.finishTimeLabel:SetPoint("TOPLEFT", finishTimeLabel.frame, "TOPRIGHT", 0, 0)
		local dkpSystemLabel = AceGUI:Create("Label")
		dkpSystemLabel:SetText(L["DKP System"])
		container:AddChild(dkpSystemLabel)
		dkpSystemLabel:SetWidth(100)
		dkpSystemLabel:SetPoint("TOPLEFT", finishTimeLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.dkpSystemLabel = AceGUI:Create("Label")
		mainFrame.dkpSystemLabel:SetColor(0.8, 0.8, 0.3)
		container:AddChild(mainFrame.dkpSystemLabel)
		mainFrame.dkpSystemLabel:SetPoint("TOPLEFT", dkpSystemLabel.frame, "TOPRIGHT", 0, 0)
		local musterScoreLabel = AceGUI:Create("Label")
		musterScoreLabel:SetText(L["Muster Score"])
		container:AddChild(musterScoreLabel)
		musterScoreLabel:SetWidth(100)
		musterScoreLabel:SetPoint("TOPLEFT", dkpSystemLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.musterScoreLabel = AceGUI:Create("Label")
		mainFrame.musterScoreLabel:SetColor(1, 0.5, 0.5)
		container:AddChild(mainFrame.musterScoreLabel)
		mainFrame.musterScoreLabel:SetPoint("TOPLEFT", musterScoreLabel.frame, "TOPRIGHT", 0, 0)
		local dismissScoreLabel = AceGUI:Create("Label")
		dismissScoreLabel:SetText(L["Dismiss Score"])
		container:AddChild(dismissScoreLabel)
		dismissScoreLabel:SetWidth(100)
		dismissScoreLabel:SetPoint("TOPLEFT", musterScoreLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.dismissScoreLabel = AceGUI:Create("Label")
		mainFrame.dismissScoreLabel:SetColor(0.5, 0.5, 1)
		container:AddChild(mainFrame.dismissScoreLabel)
		mainFrame.dismissScoreLabel:SetPoint("TOPLEFT", dismissScoreLabel.frame, "TOPRIGHT", 0, 0)
		local statusLabel = AceGUI:Create("Label")
		statusLabel:SetText(L["Status"])
		container:AddChild(statusLabel)
		statusLabel:SetWidth(100)
		statusLabel:SetPoint("TOPLEFT", dismissScoreLabel.frame, "BOTTOMLEFT", 0, -10)
		mainFrame.statusLabel = AceGUI:Create("Label")
		mainFrame.statusLabel:SetColor(0.5, 0.8, 0.9)
		container:AddChild(mainFrame.statusLabel)
		mainFrame.statusLabel:SetPoint("TOPLEFT", statusLabel.frame, "TOPRIGHT", 0, 0)
		
		mainFrame.startButton = AceGUI:Create("Button")
		mainFrame.startButton:SetText(L["Start"])
		mainFrame.startButton:SetDisabled(true)
		mainFrame.startButton:SetCallback("OnClick", function(widget, event) 
			addon:StartRaid()
		end)
		container:AddChild(mainFrame.startButton)
		mainFrame.startButton:SetWidth(100)
		mainFrame.startButton:SetPoint("TOPLEFT", statusLabel.frame, "BOTTOMLEFT", -30, -20)
		addon:SetHelp(mainFrame.startButton, L["Start current raid"])
		mainFrame.musterScoreButton = AceGUI:Create("Button")
		mainFrame.musterScoreButton:SetText(L["Muster Score"])
		mainFrame.musterScoreButton:SetDisabled(true)
		mainFrame.musterScoreButton:SetCallback("OnClick", function(widget, event)
			addon:AddMusterScore()
		end)
		container:AddChild(mainFrame.musterScoreButton)
		mainFrame.musterScoreButton:SetWidth(100)
		mainFrame.musterScoreButton:SetPoint("TOPLEFT", mainFrame.startButton.frame, "TOPRIGHT", 0, 0)
		addon:SetHelp(mainFrame.musterScoreButton, L["Add muster score"])
		mainFrame.pauseButton = AceGUI:Create("Button")
		mainFrame.pauseButton:SetText(L["Pause"])
		mainFrame.pauseButton:SetDisabled(true)
		mainFrame.pauseButton:SetCallback("OnClick", function(widget, event)
			addon:PauseRaid()
		end)
		container:AddChild(mainFrame.pauseButton)
		mainFrame.pauseButton:SetWidth(100)
		mainFrame.pauseButton:SetPoint("TOPLEFT", mainFrame.musterScoreButton.frame, "TOPRIGHT", 0, 0)
		addon:SetHelp(mainFrame.pauseButton, L["Pause current raid"])
		mainFrame.resumeButton = AceGUI:Create("Button")
		mainFrame.resumeButton:SetText(L["Resume"])
		mainFrame.resumeButton:SetDisabled(true)
		mainFrame.resumeButton:SetCallback("OnClick", function(widget, event)
			addon:ResumeRaid()
		end)
		container:AddChild(mainFrame.resumeButton)
		mainFrame.resumeButton:SetWidth(100)
		mainFrame.resumeButton:SetPoint("TOPLEFT", mainFrame.startButton.frame, "BOTTOMLEFT", 0, 0)
		addon:SetHelp(mainFrame.resumeButton, L["Resume current raid"])
		mainFrame.dismissScoreButton = AceGUI:Create("Button")
		mainFrame.dismissScoreButton:SetText(L["Dismiss Score"])
		mainFrame.dismissScoreButton:SetDisabled(true)
		mainFrame.dismissScoreButton:SetCallback("OnClick", function(widget, event)
			addon:AddDismissScore()
		end)
		container:AddChild(mainFrame.dismissScoreButton)
		mainFrame.dismissScoreButton:SetWidth(100)
		mainFrame.dismissScoreButton:SetPoint("TOPLEFT", mainFrame.resumeButton.frame, "TOPRIGHT", 0, 0)
		addon:SetHelp(mainFrame.dismissScoreButton, L["Add dismiss score"])
		mainFrame.finishButton = AceGUI:Create("Button")
		mainFrame.finishButton:SetText(L["Finish"])
		mainFrame.finishButton:SetDisabled(true)
		mainFrame.finishButton:SetCallback("OnClick", function(widget, event)
			addon:FinishRaid()
		end)
		container:AddChild(mainFrame.finishButton)
		mainFrame.finishButton:SetWidth(100)
		mainFrame.finishButton:SetPoint("TOPLEFT", mainFrame.dismissScoreButton.frame, "TOPRIGHT", 0, 0)
		addon:SetHelp(mainFrame.finishButton, L["Finish current raid"])
		
		mainFrame.exportButton = AceGUI:Create("Button")
		mainFrame.exportButton:SetText(L["Export Raid Data"])
		mainFrame.exportButton:SetWidth(100)
		container:AddChild(mainFrame.exportButton)
		mainFrame.exportButton:SetPoint("CENTER", mainFrame.dismissScoreButton.frame, "CENTER", 0, -50)
		addon:SetHelp(mainFrame.exportButton, L["Export the data of selected raid and upload to the website."])
		mainFrame.exportButton:SetCallback("OnClick", function(widget, event, button)
			container:ReleaseChildren()
			local xmlEditBox = AceGUI:Create("EditBox")
			xmlEditBox.editbox:SetScript("OnEscapePressed",nil)
			xmlEditBox.editbox:SetScript("OnEnterPressed",nil)
			xmlEditBox.editbox:SetScript("OnTextChanged",nil)
			xmlEditBox.editbox:SetScript("OnReceiveDrag", nil)
			xmlEditBox.editbox:SetScript("OnMouseDown", nil)
			xmlEditBox.editbox:SetMaxLetters(65535)
			xmlEditBox.button:Hide()
			xmlEditBox:SetLabel(L["Please copy this string."])
			container:AddChild(xmlEditBox)
			xmlEditBox:SetPoint("TOPLEFT", container.frame, 10, -100)
			xmlEditBox:SetPoint("RIGHT")
			xmlEditBox:SetText(DKPStringFormat["function"][addon.db.profile["dkpStringFormat"]](selectedRaid))
			xmlEditBox.editbox:HighlightText()
			xmlEditBox.editbox:SetFocus()
			local backButton = AceGUI:Create("Button")
			backButton:SetText(L["Back"])
			backButton:SetWidth(100)
			container:AddChild(backButton)
			backButton:SetPoint("CENTER")
			backButton:SetPoint("TOP", xmlEditBox.frame, "BOTTOM", 0 , -30)
			backButton:SetCallback("OnClick", function(widget, event, button)
				container:SelectTab("info")
			end)
		end)
	elseif group == "events" then
		container:PauseLayout()
		local columnHeaders = AceGUI:Create("SimpleGroup")
		columnHeaders:SetLayout("Flow")
		local eventNameHeader = AceGUI:Create("InteractiveLabel")
		eventNameHeader:SetWidth(100)
		eventNameHeader:SetText(L["Event name"])
		columnHeaders:AddChild(eventNameHeader)
		local timeHeader = AceGUI:Create("InteractiveLabel")
		timeHeader:SetWidth(70)
		timeHeader:SetText(L["Time"])
		columnHeaders:AddChild(timeHeader)
		local mainNumberHeader = AceGUI:Create("InteractiveLabel")
		mainNumberHeader:SetWidth(50)
		mainNumberHeader:SetText(L["Main number"])
		columnHeaders:AddChild(mainNumberHeader)
		local mainDKPHeader = AceGUI:Create("InteractiveLabel")
		mainDKPHeader:SetWidth(60)
		mainDKPHeader:SetText(L["Main dkp"])
		columnHeaders:AddChild(mainDKPHeader)
		local alternateNumberHeader = AceGUI:Create("InteractiveLabel")
		alternateNumberHeader:SetWidth(50)
		alternateNumberHeader:SetText(L["Alternate number"])
		columnHeaders:AddChild(alternateNumberHeader)
		local alternateDKPHeader = AceGUI:Create("InteractiveLabel")
		alternateDKPHeader:SetWidth(60)
		alternateDKPHeader:SetText(L["Alternate dkp"])
		columnHeaders:AddChild(alternateDKPHeader)
		container:AddChild(columnHeaders)
		columnHeaders:SetPoint("TOPLEFT")
		columnHeaders:SetPoint("RIGHT")
		columnHeaders:SetWidth(470)
		mainFrame.eventListScrollFrame = AceGUI:Create("ScrollFrame")
		mainFrame.eventListScrollFrame:SetLayout("List")
		container:AddChild(mainFrame.eventListScrollFrame)
		mainFrame.eventListScrollFrame:SetPoint("TOPLEFT", columnHeaders.frame, "BOTTOMLEFT")
		mainFrame.eventListScrollFrame:SetPoint("BOTTOMRIGHT", container.frame, "BOTTOMRIGHT", 0, 55)
		mainFrame.eventListScrollFrame:SetWidth(470)
		local moreOptionHeading = AceGUI:Create("Heading")
		moreOptionHeading:SetText(L["More operations"])
		container:AddChild(moreOptionHeading)
		moreOptionHeading:SetPoint("TOPLEFT", mainFrame.eventListScrollFrame.frame, "BOTTOMLEFT")
		moreOptionHeading:SetPoint("RIGHT")
		mainFrame.addKillsButton = AceGUI:Create("Button")
		mainFrame.addKillsButton:SetText(L["Add kills"])
		mainFrame.addKillsButton:SetWidth(100)
		container:AddChild(mainFrame.addKillsButton)
		mainFrame.addKillsButton:SetCallback("OnClick", function(widget, event)
			container:ReleaseChildren()
			if selectedRaid then
				local bossDropdown = AceGUI:Create("Dropdown")
				bossDropdown:SetLabel(L["Select a boss not be killed"])
				container:AddChild(bossDropdown)
				bossDropdown:SetWidth(240)
				bossDropdown:SetPoint("TOPLEFT", 100, -100)
				local tmpList = {}
				if currentRaid then
					for name, boss in pairs(currentRaid["bossMod"]) do
						local killed = true
						for k, v in pairs(boss["kill"]) do
							for name, value in pairs(boss["kill"][k]) do
								killed = killed and value
							end
						end
						if not killed then
							tmpList[name] = boss["name"]
						end
					end
				end
				bossDropdown:SetList(tmpList)
				bossDropdown:SetCallback("OnValueChanged", function(widget, event, value)
					bossDropdown:SetUserData("boss", value)
				end)
				local okButton = AceGUI:Create("Button")
				okButton:SetText(L["Okey"])
				okButton:SetWidth(100)
				okButton:SetCallback("OnClick", function(widget, event)
					local boss = bossDropdown:GetUserData("boss")
					if not boss then
						addon:PrintMessage("error", L["Please select a boss not be killed yet."])
						return
					end
					for k, v in pairs(currentRaid["bossMod"][boss]["kill"]) do
						for bn in pairs(v) do
							v[bn] = true
						end
					end
					addon:CheckBossKilled(currentRaid["bossMod"][boss])
					addon:ShowRaidInfo(currentRaid)
					container:SelectTab("events")
				end)
				container:AddChild(okButton)
				okButton:SetPoint("TOPLEFT", bossDropdown.frame, "BOTTOMLEFT", 10, -10)
				local cancelButton = AceGUI:Create("Button")
				cancelButton:SetText(L["Cancel"])
				cancelButton:SetWidth(100)
				cancelButton:SetCallback("OnClick", function(widget, event)
					container:SelectTab("events")
				end)
				container:AddChild(cancelButton)
				cancelButton:SetPoint("TOPRIGHT", bossDropdown.frame, "BOTTOMRIGHT", -10, -10)
			end
		end)
		mainFrame.addKillsButton:SetPoint("TOPLEFT", moreOptionHeading.frame, "BOTTOMLEFT")
		mainFrame.addRewardsAndPunishmentsButton = AceGUI:Create("Button")
		mainFrame.addRewardsAndPunishmentsButton:SetText(L["Add rewards and punishments"])
		mainFrame.addRewardsAndPunishmentsButton:SetWidth(100)
		mainFrame.addRewardsAndPunishmentsButton:SetCallback("OnClick", function(widget, event, button)
			if selectedRaid then
				container:ReleaseChildren()
				local eventNameEditBox = AceGUI:Create("EditBox")
				eventNameEditBox:SetLabel(L["Reward or punishment reason"])
				eventNameEditBox.button:ClearAllPoints()
				container:AddChild(eventNameEditBox)
				eventNameEditBox:SetPoint("TOPLEFT")
				eventNameEditBox:SetPoint("RIGHT")
				local dkpEditBox = AceGUI:Create("EditBox")
				dkpEditBox:SetLabel(L["DKP"])
				dkpEditBox.button:ClearAllPoints()
				container:AddChild(dkpEditBox)
				dkpEditBox:SetPoint("TOPLEFT", eventNameEditBox.frame , "BOTTOMLEFT")
				dkpEditBox:SetPoint("RIGHT")
				dkpEditBox:SetText(nil)

				local memberGroup = AceGUI:Create("InlineGroup")
				memberGroup:SetTitle(L["Members"])
				memberGroup:SetLayout("Fill")
				container:AddChild(memberGroup)
				memberGroup:SetPoint("TOPLEFT", dkpEditBox.frame , "BOTTOMLEFT")
				memberGroup:SetPoint("BOTTOMRIGHT", 0, 20)

				local memberScrollFrame = AceGUI:Create("ScrollFrame")
				memberScrollFrame:SetLayout("Flow")
				memberScrollFrame:SetWidth(500)
				memberGroup:AddChild(memberScrollFrame)
				local members = {}

				local function OnMemberChecked(widget, event, value)
					local name = widget:GetUserData("member")
					local exists = false
					for i, n in ipairs(members) do
						if n == name then
							if not value then
								tremove(members, i)
							end
							exists = true
						end
					end
					if value and not exists then
						tinsert(members, name)
					end
				end

				for name, member in pairs(selectedRaid["members"]) do
					local checkBox = AceGUI:Create("CheckBox")
					checkBox:SetLabel(name)
					checkBox:SetUserData("member", name)
					checkBox:SetWidth(150)
					checkBox:SetCallback("OnValueChanged", OnMemberChecked)
					checkBox.text:SetTextColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
					memberScrollFrame:AddChild(checkBox)
				end

				local addButton = AceGUI:Create("Button")
				addButton:SetText(L["Add"])
				addButton:SetWidth(100)
				addButton:SetCallback("OnClick", function(widget, event, button)
					local name = strtrim(eventNameEditBox.editbox:GetText())
					if not name or #name == 0 then
						addon:PrintMessage("error", L["Event name can not be empty."])
						return
					end
					local dkp = tonumber(dkpEditBox.editbox:GetText())
					if not dkp then
						addon:PrintMessage("error", L["DKP muster be a number."])
						return
					end
					addon:CreateEvent(name, false, dkp, members, nil, nil, nil, format(L["Event <--%s--> has been created."], name), true)
					addon:ShowRaidInfo(selectedRaid)
					container:SelectTab("events")
				end)
				container:AddChild(addButton)
				addButton:SetPoint("BOTTOMLEFT", container.frame, "BOTTOMLEFT", 110, 10)
				local cancelButton = AceGUI:Create("Button")
				cancelButton:SetText(L["Cancel"])
				cancelButton:SetWidth(100)
				cancelButton:SetCallback("OnClick", function(widget, event, button)
					container:SelectTab("events")
				end)
				container:AddChild(cancelButton)
				cancelButton:SetPoint("BOTTOMRIGHT", container.frame, "BOTTOMRIGHT", -110, 10)
			end	
		end)
		container:AddChild(mainFrame.addRewardsAndPunishmentsButton)
		mainFrame.addRewardsAndPunishmentsButton:SetPoint("CENTER", moreOptionHeading.frame, "CENTER")
		mainFrame.addRewardsAndPunishmentsButton:SetPoint("TOP", moreOptionHeading.frame, "BOTTOM")
	elseif group == "members" then
		container:PauseLayout()
		local columnHeaders = AceGUI:Create("SimpleGroup")
		columnHeaders:SetLayout("Flow")
		local nameColumnHeader = AceGUI:Create("InteractiveLabel")
		nameColumnHeader:SetWidth(110)
		nameColumnHeader:SetText(L["Name"])
		columnHeaders:AddChild(nameColumnHeader)
		local classColumnHeader = AceGUI:Create("InteractiveLabel")
		classColumnHeader:SetWidth(80)
		classColumnHeader:SetText(L["Class"])
		columnHeaders:AddChild(classColumnHeader)
		local joinTimeColumnHeader = AceGUI:Create("InteractiveLabel")
		joinTimeColumnHeader:SetWidth(80)
		joinTimeColumnHeader:SetText(L["Join time"])
		columnHeaders:AddChild(joinTimeColumnHeader)
		local leaveTimeColumnHeader = AceGUI:Create("InteractiveLabel")
		leaveTimeColumnHeader:SetWidth(80)
		leaveTimeColumnHeader:SetText(L["Leave time"])
		columnHeaders:AddChild(leaveTimeColumnHeader)
		local inRaidColumnHeader = AceGUI:Create("InteractiveLabel")
		inRaidColumnHeader:SetWidth(90)
		inRaidColumnHeader:SetText(L["In raid"])
		columnHeaders:AddChild(inRaidColumnHeader)
		container:AddChild(columnHeaders)
		columnHeaders:SetPoint("TOPLEFT")
		columnHeaders:SetPoint("RIGHT")
		columnHeaders:SetWidth(470)
		GuildRoster()
		local guildRankDropdown = AceGUI:Create("Dropdown")
		local tmpList = {}
		for i = 1, GuildControlGetNumRanks() do
			local name = GuildControlGetRankName(i)
			tmpList[name] = name
		end
		guildRankDropdown:SetList(tmpList)
		guildRankDropdown:SetLabel(L["Guild rank"])
		container:AddChild(guildRankDropdown)
		guildRankDropdown:SetPoint("BOTTOMLEFT")
		guildRankDropdown:SetCallback("OnValueChanged", function(widget, event, key)
			guildRankDropdown:SetUserData("rank", tmpList[key])
		end)
		mainFrame.importButton = AceGUI:Create("Button")
		mainFrame.importButton:SetText(L["Import from selected rank"])
		mainFrame.importButton:SetWidth(150)
		mainFrame.importButton:SetCallback("OnClick", function(widget, event, button)
			if selectedRaid then
				SetGuildRosterShowOffline()
				local rank = guildRankDropdown:GetUserData("rank")
				if rank then
					for i = 1, GetNumGuildMembers() do
						local member = {}
						local name, r = GetGuildRosterInfo(i)
						if r == rank then
							local member = selectedRaid["members"][name]
							if not member then
								local name, _, _, level, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
								member = {}
								member["name"] = name
								member["level"] = level
								member["sex"] = UnitSex(name)
								member["class"] = class
								_, member["race"] = UnitRace(name)
								member["joinTime"] = time()
								member["activeMinutes"] = 0
								member["alternateMinutes"] = 0
								selectedRaid["members"][name] = member
							end
						end
					end
				end
				container:SelectTab("members")
			end
		end)
		container:AddChild(mainFrame.importButton)
		mainFrame.importButton:SetPoint("BOTTOMLEFT", guildRankDropdown.frame, "BOTTOMRIGHT")
		local moreOptionHeading = AceGUI:Create("Heading")
		moreOptionHeading:SetText(L["More operations"])
		container:AddChild(moreOptionHeading)
		moreOptionHeading:SetPoint("BOTTOMLEFT", guildRankDropdown.frame, "TOPLEFT")
		moreOptionHeading:SetPoint("RIGHT")
		mainFrame.memberListScrollFrame = AceGUI:Create("ScrollFrame")
		mainFrame.memberListScrollFrame:SetLayout("List")
		container:AddChild(mainFrame.memberListScrollFrame)
		mainFrame.memberListScrollFrame:SetPoint("TOPLEFT", columnHeaders.frame, "BOTTOMLEFT")
		mainFrame.memberListScrollFrame:SetPoint("BOTTOM", moreOptionHeading.frame, "TOP")
		mainFrame.memberListScrollFrame:SetPoint("RIGHT")
	elseif group == "items" then
		container:PauseLayout()
		local columnHeaders = AceGUI:Create("SimpleGroup")
		columnHeaders:SetLayout("Flow")
		local itemHeader = AceGUI:Create("InteractiveLabel")
		itemHeader:SetText(L["Item name"])
		itemHeader:SetWidth(150)
		columnHeaders:AddChild(itemHeader)
		local lootTimeHeader = AceGUI:Create("InteractiveLabel")
		lootTimeHeader:SetText(L["Loot time"])
		lootTimeHeader:SetWidth(100)
		columnHeaders:AddChild(lootTimeHeader)
		local looterHeader = AceGUI:Create("InteractiveLabel")
		looterHeader:SetText(L["Looter"])
		looterHeader:SetWidth(100)
		columnHeaders:AddChild(looterHeader)
		local dkpHeader = AceGUI:Create("InteractiveLabel")
		dkpHeader:SetText(L["DKP"])
		dkpHeader:SetWidth(80)
		columnHeaders:AddChild(dkpHeader)
		container:AddChild(columnHeaders)
		columnHeaders:SetPoint("TOPLEFT")
		columnHeaders:SetPoint("RIGHT")
		columnHeaders:SetWidth(470)
		mainFrame.addLootButton = AceGUI:Create("Button")
		mainFrame.addLootButton:SetText(L["Add loot"])
		container:AddChild(mainFrame.addLootButton)
		mainFrame.addLootButton:SetPoint("CENTER")
		mainFrame.addLootButton:SetPoint("BOTTOM")
		mainFrame.addLootButton:SetCallback("OnClick", function(widget, event, button)
			container:ReleaseChildren()
			container:PauseLayout()
			local itemEditBox = AceGUI:Create("EditBox")
			itemEditBox.editbox:SetScript("OnEscapePressed",nil)
			itemEditBox.editbox:SetScript("OnEnterPressed",nil)
			itemEditBox.editbox:SetScript("OnTextChanged",nil)
			itemEditBox.editbox:SetScript("OnReceiveDrag", nil)
			itemEditBox.editbox:SetScript("OnMouseDown", nil)
			itemEditBox.button:Hide()
			itemEditBox:SetLabel(L["Item name or id"])
			container:AddChild(itemEditBox)
			addon:SetHelp(itemEditBox, L["Item mey be not find if using item name."])
			itemEditBox:SetPoint("TOPLEFT", container.frame, 120, -100)
			local memberDropdown = AceGUI:Create("Dropdown")
			local tmpList = {}
			for name, member in pairs(selectedRaid["members"]) do
				tmpList[name] = name
			end
			memberDropdown:SetList(tmpList)
			memberDropdown:SetLabel(L["Select a member"])
			container:AddChild(memberDropdown)
			memberDropdown:SetPoint("TOPLEFT", itemEditBox.frame, "BOTTOMLEFT")
			memberDropdown:SetCallback("OnValueChanged", function(widget, event, key)
				memberDropdown:SetUserData("member", key)
			end)
			local okButton = AceGUI:Create("Button")
			okButton:SetText(L["Okey"])
			okButton:SetWidth(100)
			container:AddChild(okButton)
			okButton:SetPoint("TOPLEFT", memberDropdown.frame, "BOTTOMLEFT", -20, -20)
			okButton:SetCallback("OnClick", function(widget, event, button)
				local _, itemLink = GetItemInfo(itemEditBox.editbox:GetText())
				if not itemLink then
					addon:PrintMessage("error", L["Cannot find item."])
					return
				end
				local member = memberDropdown:GetUserData("member")
				if not member then
					addon:PrintMessage("error", L["Please select a member."])
					return
				end
				addon:AddItemLoot(selectedRaid, member, itemLink)
				container:SelectTab("items")
			end)
			local cancelButton = AceGUI:Create("Button")
			cancelButton:SetText(L["Cancel"])
			cancelButton:SetWidth(100)
			container:AddChild(cancelButton)
			cancelButton:SetPoint("TOPRIGHT", memberDropdown.frame, "BOTTOMRIGHT", 20, -20)
			cancelButton:SetCallback("OnClick", function(widget, event, button)
				container:SelectTab("items")
			end)
		end)
		local moreOptionHeading = AceGUI:Create("Heading")
		moreOptionHeading:SetText(L["More operations"])
		container:AddChild(moreOptionHeading)
		moreOptionHeading:SetPoint("BOTTOM", mainFrame.addLootButton.frame, "TOP")
		moreOptionHeading:SetPoint("LEFT")
		moreOptionHeading:SetPoint("RIGHT")
		mainFrame.lootedItemListScrollFrame = AceGUI:Create("ScrollFrame")
		mainFrame.lootedItemListScrollFrame:SetLayout("List")
		container:AddChild(mainFrame.lootedItemListScrollFrame)
		mainFrame.lootedItemListScrollFrame:SetPoint("TOPLEFT", columnHeaders.frame, "BOTTOMLEFT")
		mainFrame.lootedItemListScrollFrame:SetPoint("BOTTOM", moreOptionHeading.frame, "TOP")
		mainFrame.lootedItemListScrollFrame:SetPoint("RIGHT")
	end
	addon:ShowRaidInfo(selectedRaid)	
end

--[[Methods]]
function addon:InitComponents()
	local popup = _G.StaticPopupDialogs
	if type(popup) ~= "table" then
		popup = {}
	end
	if type(popup["DCRTDeleteRaidDialog"]) ~= "table" then
		popup["DCRTDeleteRaidDialog"] = {
			text = "",
			button1 = TEXT(YES),
			button2 = TEXT(NO),
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			OnAccept = function()
				self:DeleteRaid(selectedRaid)
				return
			end
		}
	end
	if type(popup["DCRTDeleteEventDialog"]) ~= "table" then
		popup["DCRTDeleteEventDialog"] = {
			text = "",
			button1 = TEXT(YES),
			button2 = TEXT(NO),
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			OnAccept = function()
				self:DeleteEvent(selectedRaid, selectedEvent)
				self:ShowRaidInfo(selectedRaid)
				return
			end
		}
	end
	if type(popup["DCRTDeleteItemDialog"]) ~= "table" then
		popup["DCRTDeleteItemDialog"] = {
			text = "",
			button1 = TEXT(YES),
			button2 = TEXT(NO),
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
			OnAccept = function()
				self:DeleteItem(selectedRaid, selectedItem)
				self:ShowRaidInfo(selectedRaid)
				return
			end
		}
	end
	iconFrame = CreateFrame("Button", "DCRTMinimap", Minimap)
	iconFrame:SetWidth(31)
	iconFrame:SetHeight(31)
	iconFrame:SetFrameStrata("BACKGROUND")
	iconFrame:SetToplevel(true)
	iconFrame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	iconFrame:RegisterForClicks("LeftButtonUp","RightButtonUp")
	iconFrame:RegisterForDrag("LeftButton","RightButton")
	
	iconFrame:SetScript("OnDragStart", function() 
		iconFrame:LockHighlight()
		iconFrame:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			px, py = px / scale, py / scale
			local p = math.deg(math.atan2(py - my, px - mx))
			self:SetIconPosition(p)
		end)
	end)
	iconFrame:SetScript("OnDragStop", function() 
		iconFrame:SetScript("OnUpdate", nil)
		iconFrame:UnlockHighlight()
	end)
	iconFrame:SetScript("OnClick", function()
		if mainFrame then
			self:HideMainFrame()
		else
			self:ShowMainFrame()
		end
	end)
	self:SetIconPosition(self.db.profile["iconPosition"])
	
	local icon = iconFrame:CreateTexture(iconFrame:GetName() .. "Icon", "BACKGROUND")
	icon:SetTexture("Interface\\Icons\\INV_Scroll_04")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 7, -5)
	local overlay = iconFrame:CreateTexture(iconFrame:GetName() .. "Overlay", "OVERLAY")
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetWidth(53)
	overlay:SetHeight(53)
	overlay:SetPoint("TOPLEFT",iconFrame,"TOPLEFT")
	iconFrame:EnableMouse(true)
	GameTooltip:SetOwner(iconFrame, "ANCHOR_NONE")
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
	iconFrame:Show()
	
	tablet:Register(iconFrame, "children", function() 
			tablet:SetTitle(L["Diamond Crevasse Raid Tool"])
			tablet:SetHint(" |cffffffff" .. L["Developed by CN5-Tyr's hand-Mizzle"] .. "|r")
		end,
		"point", "TOPRIGHT",
		"relativePoint", "BOTTOMLEFT"
	)
end

function addon:CreateMainFrame()
	if not mainFrame then
		mainFrame = AceGUI:Create("Frame")
		mainFrame:SetTitle(L["Diamond Crevasse Raid Tool"])
		mainFrame:SetLayout("Fill")
		mainFrame.frame:SetResizable(false)
		mainFrame.sizer_se:Hide()
		mainFrame.sizer_s:Hide()
		mainFrame.sizer_e:Hide()
		mainFrame.closebutton:SetText(L["Close"])
		mainFrame:SetHeight(540)
		mainFrame.frame:SetFrameStrata("DIALOG")
		mainFrame:SetCallback("OnClose", function(container, event)
			mainFrame:ReleaseChildren()
			mainFrame = nil
		end)
		
		local tab = AceGUI:Create("TabGroup")
		tab:SetTabs({{
			text = L["Raids"],
			value = "raids"
		},{
			text = L["DKP"],
			value = "dkp"
		},{
			text = L["Items"],
			value = "items"
		},{
			text = L["Raid config"],
			value = "raid config"
		},{
			text = L["Config"],
			value = "config"
		}})
		tab:SetLayout("Flow")
		tab:SetCallback("OnGroupSelected", MainTabGroup_TabChanged)
		tab:SelectTab("raids")
		mainFrame:AddChild(tab)
		mainFrame.tab = tab
	end
end

function addon:SetIconPosition(position)
	if position <= 0 then
		position = position + 360
	elseif position > 360 then
		position = position - 360
	end
	local angle = math.rad(position or 0)
	local x,y
	local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local cos = math.cos(angle)
	local sin = math.sin(angle)
		local round = true
	if minimapShape == "ROUND" then
		-- do nothing
	elseif minimapShape == "SQUARE" then
		round = false
	elseif minimapShape == "CORNER-TOPRIGHT" then
		if cos < 0 or sin < 0 then
			round = false
		end
	elseif minimapShape == "CORNER-TOPLEFT" then
		if cos > 0 or sin < 0 then
			round = false
		end
	elseif minimapShape == "CORNER-BOTTOMRIGHT" then
		if cos < 0 or sin > 0 then
			round = false
		end
	elseif minimapShape == "CORNER-BOTTOMLEFT" then
		if cos > 0 or sin > 0 then
			round = false
		end
	elseif minimapShape == "SIDE-LEFT" then
		if cos > 0 then
			round = false
		end
	elseif minimapShape == "SIDE-RIGHT" then
		if cos < 0 then
			round = false
		end
	elseif minimapShape == "SIDE-TOP" then
		if sin < 0 then
			round = false
		end
	elseif minimapShape == "SIDE-BOTTOM" then
		if sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-TOPRIGHT" then
		if cos < 0 and sin < 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-TOPLEFT" then
		if cos > 0 and sin < 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMRIGHT" then
		if cos < 0 and sin > 0 then
			round = false
		end
	elseif minimapShape == "TRICORNER-BOTTOMLEFT" then
		if cos > 0 and sin > 0 then
			round = false
		end
	end
	if round then
		x = cos * 80
		y = sin * 80
	else
		x = 80 * 2^0.5 * cos
		y = 80 * 2^0.5 * sin
		if x < -80 then
			x = -80
		elseif x > 80 then
			x = 80
		end
		if y < -80 then
			y = -80
		elseif y > 80 then
			y = 80
		end
	end
	iconFrame:SetPoint("CENTER", Minimap, "CENTER", x, y)
	self.db.profile["iconPosition"] = position
end

function addon:PrintMessage(type, msg)
	local message = "|c00ffff00" .. L["DCRT Message:"] .. "|r"
	if type == "error" then
		message = message .. "|c00ff0000" .. msg .. "|r"
	elseif type == "pormpt" then
		message = message .. "|c0000ff00" .. msg .. "|r"
	end
	print(message)
end

function addon:SendMessage(msg, receiver)
	if self.db.profile["announcement"]["enabled"] then
		if not receiver then
			if self.db.profile["announcement"]["channels"]["RAID"] then
				SendChatMessage(L["DCRT Message:"] .. msg, "RAID")
			end
			if self.db.profile["announcement"]["channels"]["GUILD"] then
				SendChatMessage(L["DCRT Message:"] .. msg, "GUILD")
			end
		else
			if self.db.profile["announcement"]["channels"]["WHISPER"] then
				SendChatMessage(L["DCRT Message:"] .. msg, "WHISPER", nil, receiver)
			end
		end
	end
end

function addon:NewRaid(raidName, dkpSystem)
	currentRaid = {
		["raidName"] = raidName,
		["creationTime"] = time(),
		["start"] = false,
		["finish"] = false,
		["pause"] = false,
		["musterScore"] = false,
		["dismissScore"] = false,
		["members"] = {},
		["events"] = {},
		["loots"] = {},
		["difficulty"] = GetDungeonDifficulty()
	}
	if dkpSystem ~= "none" then
		currentRaid["dkpSystem"] = dkpSystem
	end
	currentRaid["bossMod"] = {}
	for bossName, boss in pairs(DCRT_BOSS_MOD[currentRaid["raidName"]]) do
		currentRaid["bossMod"][bossName] = {}
		currentRaid["bossMod"][bossName]["name"] = boss["name"]
		currentRaid["bossMod"][bossName]["kill"] = {}
		for event, targets in pairs(boss["kill"]) do
			if not currentRaid["bossMod"][bossName]["kill"][event] then
				currentRaid["bossMod"][bossName]["kill"][event] = {}
			end
			for _, target in ipairs(targets) do
				currentRaid["bossMod"][bossName]["kill"][event][target] = false
			end
		end
	end
	tinsert(addon.db.profile["raidList"], currentRaid)
	
	self:UpdateRaidList(currentRaid)
end

function addon:DeleteRaid(raid)
	if raid then
		if currentRaid == raid then
			self:FinishRaid()
			currentRaid = nil
		end
		for i, v in ipairs(self.db.profile["raidList"]) do
			if v == raid then
				tremove(self.db.profile["raidList"], i)
			end
		end
		selectedRaid = nil
		self:UpdateRaidList(selectedRaid)
	end
end

function addon:StartRaid()
	if currentRaid and not currentRaid["start"] then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnLog")
		self:RegisterEvent("CHAT_MSG_LOOT", "OnItemLooted")
		currentRaid["start"] = true
		currentRaid["startTime"] = time()
		currentTimer = self:ScheduleRepeatingTimer("OnTimer", 60)
		self:OnMembersUpdate()
		self:ShowRaidInfo(selectedRaid)
	end
end

function addon:PauseRaid()
	if currentRaid and currentRaid["start"] and not currentRaid["pause"] and not currentRaid["finish"] then
		self:CancelTimer(currentTimer)
		currentTimer = nil
		currentRaid["pause"] = true
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("CHAT_MSG_LOOT")
		self:ShowRaidInfo(selectedRaid)
	end
end

function addon:ResumeRaid()
	if currentRaid and currentRaid["start"] and currentRaid["pause"] and not currentRaid["finish"] then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnLog")
		self:RegisterEvent("CHAT_MSG_LOOT", "OnItemLooted")
		currentTimer = self:ScheduleRepeatingTimer("OnTimer", 60)
		currentRaid["pause"] = false
		self:ShowRaidInfo(currentRaid)
	end
end

function addon:FinishRaid()
	if not currentRaid["finish"] then
		self:CancelTimer(currentTimer)
		currentTimer = nil
		local timeScore = {
			["active"] = {},
			["alternate"] = {}
		}
		for name, member in pairs(currentRaid["members"]) do
			local hours, b = math.modf(member["activeMinutes"] / 60)
			if b > 0.5 then
				hours = hours + 1
			end
			if hours ~= 0 then
				if not timeScore["active"][hours] then
					timeScore["active"][hours] = {}
				end
				tinsert(timeScore["active"][hours], name)
			end
		end
		for name, member in pairs(currentRaid["members"]) do
			local hours, b = math.modf(member["alternateMinutes"] / 60)
			if b > 0.5 then
				hours = hours + 1
			end
			if hours ~= 0 then
				if not timeScore["alternate"][hours] then
					timeScore["alternate"][hours] = {}
				end
				tinsert(timeScore["alternate"][hours], name)
			end
		end
		local config = self.db.profile["raidConfigs"][currentRaid["raidName"]]
		for hours, members in pairs(timeScore["active"]) do
			self:CreateEvent(format(L["%d hours time score"], hours), false, config["timeScore"] * hours, members)
		end
		for hours, members in pairs(timeScore["alternate"]) do
			self:CreateEvent(format(L["%d hours alternate time score"], hours), false, config["alternateTimeScore"] * hours, members)
		end
		currentRaid["finish"] = true
		currentRaid["finishTime"] = time()
		currentRaid = nil
		self:ShowRaidInfo(selectedRaid)
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("CHAT_MSG_LOOT")
	end
end

function addon:CreateEvent(name, auto, dkp, members, alternate, alternateDkp, alternates, message, whisper, aor, boss)
	if currentRaid then
		local event = {
			["name"] = name,
			["time"] = time(),
			["dkp"] = dkp,
			["hasAlternate"] = alternate,
			["members"] = members,
			["alternateDkp"] = alternateDkp,
			["alternates"] = alternates,
			["boss"] = boss
		}
		tinsert(currentRaid["events"], event)
		if auto then
			if not event["members"] then
				event["members"] = {}
			end
			if alternate and not event["alternates"] then
				event["alternates"] = {}
			end
			local num = GetRealNumRaidMembers()
			for u = 1, num do
				local n = GetRaidRosterInfo(u)
				if not self:IsBaned(n) and (self.db.profile["eventsIncludeOffline"] or self:IsOnline(n))then
					if self:IsAlternate(n) and alternate then
						tinsert(event["alternates"], n)
						self:ChangeDKP(currentRaid["dkpSystem"], n, event["alternateDkp"])
					else
						tinsert(event["members"], n)
						self:ChangeDKP(currentRaid["dkpSystem"], n, event["dkp"])
					end
				end
			end
		else
			for _, member in ipairs(members) do
				self:ChangeDKP(currentRaid["dkpSystem"], member, event["dkp"])
			end
			if alternate then
				for _, member in ipairs(alternates) do
					self:ChangeDKP(currentRaid["dkpSystem"], member, event["alternateDkp"])
				end
			end
		end
		if whisper then
			if event["members"] then
				for i, v in ipairs(event["members"]) do
					self:SendMessage(message .. format(L["you get %s DKP."], event["dkp"]), v)
				end
			end
			if event["alternates"] then
				for i, v in ipairs(event["alternates"]) do
					self:SendMessage(message .. format(L["you get %s DKP."], event["alternateDkp"]), v)
				end
			end
		end
		
		if message then
			if alternate then
				self:SendMessage(message .. format(L["Related members in main parties get %s DKP, in alternate parties get %s DKP."], event["dkp"], event["alternateDkp"]))
			else
				self:SendMessage(message .. format(L["Related members in raid get %s DKP."], event["dkp"]))
			end
		end
		if aor then
			self:SendAlternateOutofRaidMessage(message, event)
		end
	end
end

function addon:AlterEvent(event, name, dkp, alternate, alternateDkp)
	if selectedRaid and event then
		local message = format(L["Event<--%s--> has been altered:"], event["name"])
		if name then
			event["name"] = name
			message = message .. format(L["event name has been changed to <--%s-->,"], name)
		end
		if dkp then
			for _, member in ipairs(event["members"]) do
				self:ChangeDKP(selectedRaid["dkpSystem"], member, dkp - event["dkp"])
			end
			event["dkp"] = dkp
			message = message .. format(L["dkp has been changed to <--%s-->,"], dkp)
		end
		if alternate ~= nil then
			if alternate == true then
				if not event["alternates"] then
					event["alternates"] = {}
				end
				if not event["alternateDkp"] then
					event["alternateDkp"] = 0
				end
				message = message .. L["has alternate,"]
			else
				event["alternates"] = nil
				event["alternateDkp"] = nil
				message = message .. L["donot has alternate,"]
			end
			event["hasAlternate"] = alternate
		end
		if alternateDkp and event["alternateDkp"] then
			for _, member in ipairs(event["alternates"]) do
				self:ChangeDKP(selectedRaid["dkpSystem"], member, alternateDkp - event["alternateDkp"])
			end
			event["alternateDkp"] = alternateDkp
			message = message .. format(L["alternate dkp has been changed to <--%s-->,"], alternateDkp)
		end
		self:SendMessage(message)
	end
end

function addon:ModifyMemberForEvent(event, member, type, option)
	if selectedRaid and selectedRaid["members"][member] then
		if option == "add" then
			if type == "main" then
				local exists = false
				for _, name in ipairs(event["members"]) do
					if name == member then
						exists = true
						break
					end
				end
				if not exists then
					tinsert(event["members"], member)
					self:ChangeDKP(selectedRaid["dkpSystem"], member, event["dkp"])
					self:SendMessage(format(L["You have been added to event <--%s-->, get %s dkp."], event["name"], event["dkp"]), member)
				end
			elseif type == "alternate" then
				local exists = false
				for _, name in ipairs(event["alternates"]) do
					if name == member then
						exists = true
						break
					end
				end
				if not exists then
					tinsert(event["alternates"], member)
					self:ChangeDKP(selectedRaid["dkpSystem"], member, event["alternateDkp"])
					self:SendMessage(format(L["You have been added to event <--%s--> aternate, get %s dkp."], event["name"], event["alternateDkp"]), member)
				end
			end
		elseif option == "remove" then
			if type == "main" then
				for i, name in ipairs(event["members"]) do
					if name == member then
						tremove(event["members"], i)
						self:ChangeDKP(selectedRaid["dkpSystem"], member, -event["dkp"])
						self:SendMessage(format(L["You have been removed from event <--%s-->, deduct %s dkp."], event["name"], event["dkp"]), member)
						break
					end
				end
			elseif type == "alternate" then
				for i, name in ipairs(event["alternates"]) do
					if name == member then
						tremove(event["alternates"], i)
						self:ChangeDKP(selectedRaid["dkpSystem"], member, -event["alternateDkp"])
						self:SendMessage(format(L["You have been removed from event <--%s--> alternate, deduct %s dkp."], event["name"], event["alternateDkp"]), member)
						break
					end
				end
			end
		end
	end
end

function addon:DeleteEvent(raid, event)
	if raid and event then
		for i, e in ipairs(raid["events"]) do
			if e == event then
				tremove(raid["events"], i)
				for _, member in ipairs(event["members"]) do
					self:ChangeDKP(raid["dkpSystem"], member, -event["dkp"])
				end
				if event["hasAlternate"] then
					for _, member in ipairs(event["alternates"]) do
						self:ChangeDKP(raid["dkpSystem"], member, -event["alternateDkp"])
					end
				end
				self:SendMessage(format(L["Event <--%s--> has been deleted."], event["name"]))
				return
			end
		end
	end
end

function addon:AddMusterScore()
	if currentRaid and not currentRaid["musterScore"] then
		local config = self.db.profile["raidConfigs"][currentRaid["raidName"]]
		local dkp = 0
		if config then
			dkp = config["musterScore"]
		end
		self:CreateEvent(L["Muster Score"], true, dkp, nil, false, 0, nil, L["Muster score has been added."], false, true)
		currentRaid["musterScore"] = true
		self:ShowRaidInfo(selectedRaid)
	end
end

function addon:AddDismissScore()
	if currentRaid and not currentRaid["dismissScore"] then
		local config = self.db.profile["raidConfigs"][currentRaid["raidName"]]
		local dkp = 0
		if config then
			dkp = config["dismissScore"]
		end
		self:CreateEvent(L["Dismiss Score"], true, dkp, nil, false, 0, nil, L["Dismiss score has been added."], false, true)
		currentRaid["dismissScore"] = true
		self:ShowRaidInfo(selectedRaid)
	end
end

function addon:SendAlternateOutofRaidMessage(msg, event)
	if currentRaid and self.db.profile["alternateOutofRaid"]["enabled"] then
		currentRaid["alternateOutofRaidEvent"] = event
		local counter = 30
		local timer = self:ScheduleRepeatingTimer(function()
			if currentRaid and self.db.profile["alternateOutofRaid"]["enabled"] then
				if counter == 30 then
					SendChatMessage(L["DCRT Message:"] .. msg .. format(L["Members who is not in raid please whisper me \"%s\" in %d seconds."], self.db.profile["alternateOutofRaid"]["command"], counter), "GUILD")
				elseif counter == 0 then
					currentRaid["alternateOutofRaidEvent"] = nil
					SendChatMessage(L["DCRT Message:"] .. L["Alternate outof raid has end, please do not send whisper message."], "GUILD")
				end
				counter = counter - 1
			end
		end, 1)
	end
end

function addon:AlternateOutofRaid(member)
	if self.db.profile["alternateOutofRaid"]["enabled"] then
		if currentRaid and currentRaid["alternateOutofRaidEvent"] then
			local event = currentRaid["alternateOutofRaidEvent"]
			if currentRaid["members"][member] then
				if not self:IsBaned(sender) then
					if event["hasAlternate"] then
						for _, v in ipairs(event["members"]) do
							if v == member then
								self:SendMessage(L["You has been a alternate or main."], member)
								return
							end
						end
						for _, v in ipairs(event["alternates"]) do
							if v == member then
								self:SendMessage(L["You has been a alternate or main."], member)
								return
							end
						end
						tinsert(event["alternates"], member)
						self:ChangeDKP(currentRaid["dkpSystem"], member, event["dkp"])
						self:SendMessage(L["Alternate succeed."], member)
					else
						for _, v in ipairs(event["members"]) do
							if v == member then
								self:SendMessage(L["You has been a alternate or main."], member)
								return
							end
						end
						tinsert(event["members"], member)
						self:ChangeDKP(currentRaid["dkpSystem"], member, event["dkp"])
						self:SendMessage(L["Alternate succeed."], member)
					end
				else
					self:SendMessage(L["You do not have the right to be a alternate, you have been baned."], member)
				end
			else
				self:SendMessage(L["You do not have the right to be a alternate, you muster join the raid first."], member)
			end
		else
			self:SendMessage(L["No event for alternate."], member)
		end
	end
end

function addon:QueryDKP(member, dkpSystem, args)
	local dkpData = {}
	if self.db.profile["whisperQuery"]["enabled"] and dkpSystem then
		local system = self.db.profile["dkp"]["list"][dkpSystem]
		if self.db.profile["whisperQuery"]["querySelfOnly"] or #args == 0 then
			if system["data"][member] then
				tinsert(dkpData, {
					["name"] = member,
					["class"] = system["data"][member]["class"],
					["dkp"] = system["data"][member]["dkp"]
				})
			else
				tinsert(dkpData, {
					["name"] = member,
					["class"] = "UNKNOW",
					["dkp"] = 0
				})
			end
		elseif self.db.profile["whisperQuery"]["fuzzyQuery"] then
			for name, member in pairs(system["data"]) do
				if strfind(strupper(name), strupper(args)) then
					tinsert(dkpData, {
						["name"] = name,
						["class"] = member["class"],
						["dkp"] = member["dkp"]
					})
				elseif member["class"] then
					if strfind(strupper(L[member["class"]]), strupper(args)) then
						tinsert(dkpData, {
							["name"] = name,
							["class"] = member["class"],
							["dkp"] = member["dkp"]
						})
					end
				end
			end
		else
			for name, member in pairs(system["data"]) do
				if strupper(name) == strupper(args) then
					tinsert(dkpData, {
						["name"] = name,
						["class"] = member["class"],
						["dkp"] = member["dkp"]
					})
				elseif member["class"] then
					if strupper(L[member["class"]]) == strupper(args) then
						tinsert(dkpData, {
							["name"] = name,
							["class"] = member["class"],
							["dkp"] = member["dkp"]
						})
					end
				end
			end
		end
	end
	return dkpData
end

function addon:SendDKPMessage(dkpName, dkpData, channel, receiver)
	if receiver or channel ~= "WHISPER" then
		SendChatMessage(L["--------DCRT DKP query result---------"], channel, nil, receiver)
		if #dkpData == 0 then
			SendChatMessage(L["-------------No data--------------"], channel, nil, receiver)
		end
	end
	for _, v in ipairs(dkpData) do
		if not receiver and channel == "WHISPER" then
			SendChatMessage(L["--------DCRT DKP query result---------"], "WHISPER", nil, v["name"])
			SendChatMessage(L["DCRT DKP Message:"] .. "<<" .. dkpName .. ">>--" .. L[v["class"]] .. "--" .. v["name"] .. "  DKP:" .. v["dkp"], "WHISPER", nil, v["name"])
		else
			SendChatMessage(L["DCRT DKP Message:"] .. "<<" .. dkpName .. ">>--" .. L[v["class"]] .. "--" .. v["name"] .. "  DKP:" .. v["dkp"], channel, nil, receiver)
		end
	end
end

function addon:IsMain(member)
	if currentRaid then
		if currentRaid["members"][member] then
			return self.db.profile["raidConfigs"][currentRaid["raidName"]]["mainParties"][currentRaid["members"][member]["subgroup"]]
		end
	end
end

function addon:IsAlternate(member)
	if currentRaid and currentRaid["members"][member] then
		return self.db.profile["raidConfigs"][currentRaid["raidName"]]["alternateParties"][currentRaid["members"][member]["subgroup"]]
	end
end

function addon:IsBaned(member)
	if currentRaid and currentRaid["members"][member] then
		return self.db.profile["raidConfigs"][currentRaid["raidName"]]["banedParties"][currentRaid["members"][member]["subgroup"]]
	end
end

function addon:IsOnline(member)
	if currentRaid and currentRaid["members"][member] then
		return currentRaid["members"][member]["online"]
	end
end

function addon:UpdateRaidList(raid)
	mainFrame.raidListScrollFrame:ReleaseChildren()
	local function OnRaidCheckBoxChecked(widget, event, value)
		widget:SetValue(true)
		selectedRaid = widget:GetUserData("raid")
		self:UpdateRaidList(selectedRaid)
	end
	mainFrame.raidCheckBoxes = {}
	for i = #self.db.profile["raidList"], 1, -1 do
		local v = self.db.profile["raidList"][i]
		local raidCheckBox = AceGUI:Create("CheckBox")
		raidCheckBox:SetLabel(date(DATE_FORMAT, v["creationTime"]) .. " " .. L[v["raidName"]])
		raidCheckBox:SetUserData("raid", v)
		raidCheckBox:SetFullWidth(true)
		mainFrame.raidCheckBoxes[v["creationTime"]] = raidCheckBox
		if v == raid then
			raidCheckBox:SetValue(true)
			selectedRaid = v
			self:ShowRaidInfo(raidCheckBox:GetUserData("raid"))
		end
		raidCheckBox:SetCallback("OnValueChanged",OnRaidCheckBoxChecked)
		mainFrame.raidListScrollFrame:AddChild(raidCheckBox)
		self:SetHelp(raidCheckBox, date(DATE_TIME_FORMAT, v["creationTime"]) .. " " .. L[v["raidName"]])
	end
	if not raid then
		self:ShowRaidInfo(currentRaid)
	end
end

function addon:SetHelp(widget, msg)
	widget:SetUserData("help", msg)
	if type(widget.events["OnEnter"]) == "function" then
		widget:SetUserData("OnEnter", widget.events["OnEnter"])
	end
	if type(widget.events["OnLeave"]) == "function" then
		widget:SetUserData("OnLeave", widget.events["OnLeave"])
	end
	widget:SetCallback("OnEnter", function(widget, event)
		mainFrame:SetStatusText(widget:GetUserData("help"))
		if type(widget:GetUserData("OnEnter")) == "function" then
			widget:GetUserData("OnEnter")(widget, event)
		end
	end)
	widget:SetCallback("OnLeave", function(widget, event)
		mainFrame:SetStatusText(nil)
		if type(widget:GetUserData("OnLeave")) == "function" then
			widget:GetUserData("OnLeave")(widget, event)
		end
	end)
	
end

function addon:UpdateDKPList(dkpSystem, member)
	local system = self.db.profile["dkp"]["list"][dkpSystem]
	if system then
		if not system["data"][member] then
			system["data"][member] = {
				["class"] = select(2,UnitClass(member)),
				["dkp"] = 0
			}
		end
		if not system["data"][member]["class"] then
			system["data"][member]["class"] = select(2,UnitClass(member))
		end
	end
end

function addon:ShowRaidInfo(raid)
	mainFrame.newRaidButton:SetDisabled(currentRaid or GetRealNumRaidMembers() <= 0)
	local raidInfoGroup = mainFrame.raidInfoTabGroup:GetUserData("group")
	if raid and mainFrame then
		selectedRaid = raid
		if mainFrame.raidCheckBoxes then
			mainFrame.raidCheckBoxes[raid["creationTime"]]:SetValue(true)
		end
		if raidInfoGroup == "info" then
			mainFrame.raidNameLabel:SetText(L[raid["raidName"]])
			mainFrame.creationTimeLabel:SetText(date(DATE_TIME_FORMAT, raid["creationTime"]))
			if raid["start"] then
				mainFrame.startTimeLabel:SetText(date(DATE_TIME_FORMAT, raid["startTime"]))
			else
				mainFrame.startTimeLabel:SetText(nil)
			end
			if raid["finish"] then
				mainFrame.finishTimeLabel:SetText(date(DATE_TIME_FORMAT, raid["finishTime"]))
			else
				mainFrame.finishTimeLabel:SetText(nil)
			end
			if raid["dkpSystem"] then
				mainFrame.dkpSystemLabel:SetText(raid["dkpSystem"])
			else 
				mainFrame.dkpSystemLabel:SetText(L["None"])
			end
			if raid["musterScore"] then
				mainFrame.musterScoreLabel:SetText(L["added"])
			else
				mainFrame.musterScoreLabel:SetText(L["not add"])
			end
			if raid["dismissScore"] then
				mainFrame.dismissScoreLabel:SetText(L["added"])
			else
				mainFrame.dismissScoreLabel:SetText(L["not add"])
			end
			if not raid["start"] then
				mainFrame.statusLabel:SetText(L["not start"])
			elseif raid["pause"] then
				mainFrame.statusLabel:SetText(L["paused"])
			elseif raid["finish"] then
				mainFrame.statusLabel:SetText(L["finished"])
			else
				mainFrame.statusLabel:SetText(L["in progress"])
			end
			mainFrame.startButton:SetDisabled(raid["start"])
			mainFrame.musterScoreButton:SetDisabled(not raid["start"] or raid["musterScore"] or raid["finish"])
			mainFrame.pauseButton:SetDisabled(not raid["start"] or raid["pause"] or raid["finish"])
			mainFrame.resumeButton:SetDisabled(not raid["start"] or not raid["pause"] or raid["finish"])
			mainFrame.dismissScoreButton:SetDisabled(not raid["start"] or raid["dismissScore"] or raid["finish"])
			mainFrame.finishButton:SetDisabled(not raid["start"] or raid["finish"])
			mainFrame.exportButton:SetDisabled(not raid["finish"])
		elseif raidInfoGroup == "events" then
			mainFrame.eventListScrollFrame:ReleaseChildren()
			local function OnEventLableClick(widget, e, button)
				local event = widget:GetUserData("event")
				if event then
					if IsControlKeyDown() then
						selectedEvent = event
						_G.StaticPopupDialogs["DCRTDeleteEventDialog"]["text"] = format(L["Are you sure to delte the %s recode?"], selectedEvent["name"])
						_G.StaticPopup_Show("DCRTDeleteEventDialog")
						return
					end
					local container = mainFrame.tab;
					container:ReleaseChildren()
					local OnHasAlternateChanged
					
					local baseHeading = AceGUI:Create("Heading")
					baseHeading:SetText(L["Event base info"])
					container:AddChild(baseHeading)
					baseHeading:SetPoint("TOPLEFT")
					baseHeading:SetPoint("RIGHT")
					local eventNameEditBox = AceGUI:Create("EditBox")
					eventNameEditBox:SetLabel(L["Event name"])
					container:AddChild(eventNameEditBox)
					eventNameEditBox:SetPoint("TOPLEFT", baseHeading.frame, "BOTTOMLEFT")
					eventNameEditBox:SetPoint("RIGHT")
					eventNameEditBox:SetText(event["name"])
					eventNameEditBox:SetCallback("OnEnterPressed", function(widget, e, text)
						self:AlterEvent(event, text)
					end)
					local dkpEditBox = AceGUI:Create("EditBox")
					dkpEditBox:SetLabel(L["Main dkp"])
					dkpEditBox:SetText(event["dkp"])
					dkpEditBox:SetCallback("OnEnterPressed", function(widget, e, text)
						local dkp = tonumber(text)
						if not dkp then
							self:PrintMessage("error", L["DKP muster be a number."])
							dkpEditBox:SetText(event["dkp"])
							return
						end
						self:AlterEvent(event, nil, dkp)
					end)
					container:AddChild(dkpEditBox)
					dkpEditBox:SetPoint("TOPLEFT", eventNameEditBox.frame, "BOTTOMLEFT")
					dkpEditBox:SetPoint("RIGHT")
					local hasAlternateCheckBox = AceGUI:Create("CheckBox")
					hasAlternateCheckBox:SetLabel(L["Has alternate"])
					hasAlternateCheckBox:SetValue(event["hasAlternate"])
					hasAlternateCheckBox:SetCallback("OnValueChanged", function(widget, e, value)
						self:AlterEvent(event, nil, nil, value)
						OnHasAlternateChanged()
					end)
					container:AddChild(hasAlternateCheckBox)
					hasAlternateCheckBox:SetPoint("TOPLEFT", dkpEditBox.frame, "BOTTOMLEFT")
					hasAlternateCheckBox:SetPoint("RIGHT")
					local alternateDkpEditBox = AceGUI:Create("EditBox")
					alternateDkpEditBox:SetLabel(L["Alternate dkp"])
					alternateDkpEditBox:SetText(event["alternateDkp"])
					alternateDkpEditBox:SetCallback("OnEnterPressed", function(widget, e, text)
						local dkp = tonumber(text)
						if not dkp then
							self:PrintMessage("error", L["DKP muster be a number."])
							alternateDkpEditBox:SetText(e["alternateDkp"])
							return
						end
						self:AlterEvent(event, nil, nil, nil, dkp)
					end)
					container:AddChild(alternateDkpEditBox)
					alternateDkpEditBox:SetPoint("TOPLEFT", hasAlternateCheckBox.frame, "BOTTOMLEFT")
					alternateDkpEditBox:SetPoint("RIGHT")
					
					local membersHeading = AceGUI:Create("Heading")
					membersHeading:SetText(L["Members"])
					container:AddChild(membersHeading)
					
					membersHeading:SetPoint("TOPLEFT", alternateDkpEditBox.frame, "BOTTOMLEFT")
					membersHeading:SetPoint("RIGHT")
					
					local selectedMember
					local selectedMainMember
					local selectedAlternateMember
					local UpdateMemberLists
					
					local mainMembersGroup = AceGUI:Create("InlineGroup")
					mainMembersGroup:SetTitle(L["Main members"])
					mainMembersGroup:SetLayout("Fill")
					container:AddChild(mainMembersGroup)
					mainMembersGroup:SetWidth(150)
					mainMembersGroup:SetPoint("TOPLEFT", membersHeading.frame, "BOTTOMLEFT")
					mainMembersGroup:SetPoint("BOTTOM")
					local mainMemberListScrollFrame = AceGUI:Create("ScrollFrame")
					mainMembersGroup:AddChild(mainMemberListScrollFrame)
					
					local addToMainButton = AceGUI:Create("Button")
					addToMainButton:SetText("<<")
					addToMainButton:SetWidth(50)
					addToMainButton:SetCallback("OnClick", function(widget, e, button)
						if selectedMember then
							self:ModifyMemberForEvent(event, selectedMember:GetUserData("name"), "main", "add")
							selectedMember = nil
							UpdateMemberLists()
						end
					end)
					container:AddChild(addToMainButton)
					addToMainButton:SetPoint("TOPLEFT", mainMembersGroup.frame, "TOPRIGHT", 0, -80)
					
					local deleteFromMainButton = AceGUI:Create("Button")
					deleteFromMainButton:SetText(">>")
					deleteFromMainButton:SetWidth(50)
					deleteFromMainButton:SetCallback("OnClick", function(widget, e, button)
						if selectedMainMember then
							self:ModifyMemberForEvent(event, selectedMainMember:GetUserData("name"), "main", "remove")
							selectedMainMember = nil
							UpdateMemberLists()
						end
					end)
					container:AddChild(deleteFromMainButton)
					deleteFromMainButton:SetPoint("BOTTOMLEFT", mainMembersGroup.frame, "BOTTOMRIGHT", 0, 80)
					
					local membersGroup = AceGUI:Create("InlineGroup")
					membersGroup:SetTitle(L["All members"])
					membersGroup:SetLayout("Fill")
					local memberListScrollFrame = AceGUI:Create("ScrollFrame")
					membersGroup:AddChild(memberListScrollFrame)
					container:AddChild(membersGroup)
					membersGroup:SetWidth(150)
					membersGroup:SetPoint("TOP", mainMembersGroup.frame, "TOP")
					membersGroup:SetPoint("LEFT", addToMainButton.frame, "RIGHT")
					membersGroup:SetPoint("BOTTOM")
					
					local addToAlternateButton = AceGUI:Create("Button")
					addToAlternateButton:SetText(">>")
					addToAlternateButton:SetWidth(50)
					addToAlternateButton:SetCallback("OnClick", function(widget, e, button)
						if selectedMember then
							self:ModifyMemberForEvent(event, selectedMember:GetUserData("name"), "alternate", "add")
							selectedMember = nil
							UpdateMemberLists()
						end
					end)
					container:AddChild(addToAlternateButton)
					addToAlternateButton:SetPoint("TOPLEFT", membersGroup.frame, "TOPRIGHT", 0, -80)
					
					local deleteFromAlternateButton = AceGUI:Create("Button")
					deleteFromAlternateButton:SetText("<<")
					deleteFromAlternateButton:SetWidth(50)
					deleteFromAlternateButton:SetCallback("OnClick", function(widget, e, button)
						if selectedAlternateMember then
							self:ModifyMemberForEvent(event, selectedAlternateMember:GetUserData("name"), "alternate", "remove")
							selectedAlternateMember = nil
							UpdateMemberLists()
						end
					end)
					container:AddChild(deleteFromAlternateButton)
					deleteFromAlternateButton:SetPoint("BOTTOMLEFT", membersGroup.frame, "BOTTOMRIGHT", 0, 80)
					
					local alternateMembersGroup = AceGUI:Create("InlineGroup")
					alternateMembersGroup:SetTitle(L["Alternate members"])
					alternateMembersGroup:SetLayout("Fill")
					local alternateMemberListScrollFrame = AceGUI:Create("ScrollFrame")
					alternateMembersGroup:AddChild(alternateMemberListScrollFrame)
					container:AddChild(alternateMembersGroup)
					alternateMembersGroup:SetWidth(150)
					alternateMembersGroup:SetPoint("TOP", membersGroup.frame, "TOP")
					alternateMembersGroup:SetPoint("LEFT", addToAlternateButton.frame, "RIGHT")
					alternateMembersGroup:SetPoint("BOTTOM")
					
					local backButton = AceGUI:Create("Button")
					backButton:SetText(L["Back"])
					backButton:SetWidth(80)
					container:AddChild(backButton)
					backButton:SetPoint("BOTTOMRIGHT")
					backButton:SetCallback("OnClick", function(widget, event, button)
						container:SelectTab("raids")
						mainFrame.raidInfoTabGroup:SelectTab("events")
					end)
					
					local function OnMemberClick(widget, event, button)
						if selectedMember then
							selectedMember:SetHighlight(0.4, 0.4, 0.4, 0.4)
							selectedMember.frame:SetScript("OnEnter", function()
								this.obj.highlight:Show()
								this.obj:Fire("OnEnter")
							end)
							selectedMember.frame:SetScript("OnLeave", function()
								this.obj.highlight:Hide()
								this.obj:Fire("OnLeave")
							end)
							selectedMember.highlight:Hide()
						end
						widget:SetHighlight(0.2, 0.2, 0.4, 1)
						widget.highlight:Show()
						widget.frame:SetScript("OnEnter", function()
							this.obj:Fire("OnEnter")
						end)
						widget.frame:SetScript("OnLeave", function()
							this.obj:Fire("OnLeave")
						end)
						selectedMember = widget
					end
					
					local function OnMainMemberClick(widget, event, button)
						if selectedMainMember then
							selectedMainMember:SetHighlight(0.4, 0.4, 0.4, 0.4)
							selectedMainMember.frame:SetScript("OnEnter", function()
								this.obj.highlight:Show()
								this.obj:Fire("OnEnter")
							end)
							selectedMainMember.frame:SetScript("OnLeave", function()
								this.obj.highlight:Hide()
								this.obj:Fire("OnLeave")
							end)
							selectedMainMember.highlight:Hide()
						end
						widget:SetHighlight(0.2, 0.2, 0.4, 1)
						widget.highlight:Show()
						widget.frame:SetScript("OnEnter", function()
							this.obj:Fire("OnEnter")
						end)
						widget.frame:SetScript("OnLeave", function()
							this.obj:Fire("OnLeave")
						end)
						selectedMainMember = widget
					end
					
					local function OnAlternateMemberClick(widget, event, button)
						if selectedAlternateMember then
							selectedAlternateMember:SetHighlight(0.4, 0.4, 0.4, 0.4)
							selectedAlternateMember.frame:SetScript("OnEnter", function()
								this.obj.highlight:Show()
								this.obj:Fire("OnEnter")
							end)
							selectedAlternateMember.frame:SetScript("OnLeave", function()
								this.obj.highlight:Hide()
								this.obj:Fire("OnLeave")
							end)
							selectedAlternateMember.highlight:Hide()
						end
						widget:SetHighlight(0.2, 0.2, 0.4, 1)
						widget.highlight:Show()
						widget.frame:SetScript("OnEnter", function()
							this.obj:Fire("OnEnter")
						end)
						widget.frame:SetScript("OnLeave", function()
							this.obj:Fire("OnLeave")
						end)
						selectedAlternateMember = widget
					end
					
					UpdateMemberLists = function()
						memberListScrollFrame:ReleaseChildren()
						mainMemberListScrollFrame:ReleaseChildren()
						alternateMemberListScrollFrame:ReleaseChildren()
						for name, member in pairs(selectedRaid["members"]) do
							local exists = false
							for _, n in ipairs(event["members"]) do
								if name == n then
									exists = true
									break
								end
							end
							if event["hasAlternate"] then
								for _, n in ipairs(event["alternates"]) do
									if name == n then
										exists = true
										break
									end
								end
							end
							if not exists then
								local label = AceGUI:Create("InteractiveLabel")
								label:SetText(name)
								label:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
								label:SetHighlight(0.4, 0.4, 0.4, 0.4)
								label:SetUserData("name", name)
								label:SetCallback("OnClick", OnMemberClick)
								memberListScrollFrame:AddChild(label)
							end
						end
						for _, name in ipairs(event["members"]) do
							local member = selectedRaid["members"][name]
							local label = AceGUI:Create("InteractiveLabel")
							label:SetText(name)
							label:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
							label:SetHighlight(0.4, 0.4, 0.4, 0.4)
							label:SetUserData("name", name)
							label:SetCallback("OnClick", OnMainMemberClick)
							mainMemberListScrollFrame:AddChild(label)
						end
						if event["hasAlternate"] then
							for _, name in ipairs(event["alternates"]) do
								local member = selectedRaid["members"][name]
								local label = AceGUI:Create("InteractiveLabel")
								label:SetText(name)
								label:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
								label:SetHighlight(0.4, 0.4, 0.4, 0.4)
								label:SetUserData("name", name)
								label:SetCallback("OnClick", OnAlternateMemberClick)
								alternateMemberListScrollFrame:AddChild(label)
							end
						end
					end
					
					OnHasAlternateChanged = function()
						if event["hasAlternate"] then
							alternateDkpEditBox.frame:Show()
							alternateDkpEditBox:SetText(event["alternateDkp"])
							alternateMembersGroup.frame:Show()
							addToAlternateButton.frame:Show()
							deleteFromAlternateButton.frame:Show()
						else
							alternateMembersGroup.frame:Hide()
							addToAlternateButton.frame:Hide()
							deleteFromAlternateButton.frame:Hide()
						end
						UpdateMemberLists()
					end
					OnHasAlternateChanged()
				end
			end
			for _, event in ipairs (raid["events"]) do
				local sg = AceGUI:Create("SimpleGroup")
				sg:SetLayout("Flow")
				sg:SetFullWidth(true)
				local eventNameColumn = AceGUI:Create("InteractiveLabel")
				eventNameColumn:SetText(event["name"])
				eventNameColumn:SetWidth(100)
				eventNameColumn:SetColor(1, 0.8, 0)
				eventNameColumn:SetHighlight(0.4,0.4,0.4,0.4)
				eventNameColumn:SetUserData("event", event)
				eventNameColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(eventNameColumn)
				local timeColumn = AceGUI:Create("InteractiveLabel")
				timeColumn:SetText(date(TIME_FORMAT, event["time"]))
				timeColumn:SetWidth(70)
				timeColumn:SetColor(0.5, 0, 0.7)
				timeColumn:SetHighlight(0.4,0.4,0.4,0.4)
				timeColumn:SetUserData("event", event)
				timeColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(timeColumn)
				local mainNumberColumn = AceGUI:Create("InteractiveLabel")
				mainNumberColumn:SetText(#event["members"])
				mainNumberColumn:SetWidth(50)
				mainNumberColumn:SetColor(0, 0.5, 0.8)
				mainNumberColumn:SetHighlight(0.4,0.4,0.4,0.4)
				mainNumberColumn:SetUserData("event", event)
				mainNumberColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(mainNumberColumn)
				local mainDKPColumn = AceGUI:Create("InteractiveLabel")
				mainDKPColumn:SetText(event["dkp"])
				mainDKPColumn:SetWidth(60)
				if event["dkp"] < 0 then
					mainDKPColumn:SetColor(1, 0, 0)
				elseif event["dkp"] > 0 then
					mainDKPColumn:SetColor(0, 0.8, 0)
				end
				mainDKPColumn:SetHighlight(0.4,0.4,0.4,0.4)
				mainDKPColumn:SetUserData("event", event)
				mainDKPColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(mainDKPColumn)
				local alternateNumberColumn = AceGUI:Create("InteractiveLabel")
				if event["hasAlternate"] then
					alternateNumberColumn:SetText(#event["alternates"])
					alternateNumberColumn:SetColor(0, 0.5, 0.8)
				else
					alternateNumberColumn:SetText(" ")
				end
				alternateNumberColumn:SetWidth(50)
				alternateNumberColumn:SetHighlight(0.4,0.4,0.4,0.4)
				alternateNumberColumn:SetUserData("event", event)
				alternateNumberColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(alternateNumberColumn)
				local alternateDKPColumn = AceGUI:Create("InteractiveLabel")
				if event["hasAlternate"] then
					alternateDKPColumn:SetText(event["alternateDkp"])
					if event["alternateDkp"] < 0 then
						alternateDKPColumn:SetColor(1, 0, 0)
					elseif event["alternateDkp"] > 0 then
						alternateDKPColumn:SetColor(0, 0.8, 0)
					end
				else
					alternateDKPColumn:SetText(" ")
				end
				alternateDKPColumn:SetWidth(60)
				alternateDKPColumn:SetHighlight(0.4,0.4,0.4,0.4)
				alternateDKPColumn:SetUserData("event", event)
				alternateDKPColumn:SetCallback("OnClick", OnEventLableClick)
				sg:AddChild(alternateDKPColumn)
				mainFrame.eventListScrollFrame:AddChild(sg)
				local function showHighlight()
					eventNameColumn.highlight:Show()
					timeColumn.highlight:Show()
					mainNumberColumn.highlight:Show()
					mainDKPColumn.highlight:Show()
					alternateNumberColumn.highlight:Show()
					alternateDKPColumn.highlight:Show()
				end
				local function hideHighlight()
					eventNameColumn.highlight:Hide()
					timeColumn.highlight:Hide()
					mainNumberColumn.highlight:Hide()
					mainDKPColumn.highlight:Hide()
					alternateNumberColumn.highlight:Hide()
					alternateDKPColumn.highlight:Hide()
				end
				local maxHeight = max(eventNameColumn.frame:GetHeight(), timeColumn.frame:GetHeight(), mainNumberColumn.frame:GetHeight(), mainDKPColumn.frame:GetHeight(), alternateNumberColumn.frame:GetHeight(), alternateDKPColumn.frame:GetHeight())
				eventNameColumn:SetHeight(maxHeight)
				timeColumn:SetHeight(maxHeight)
				mainNumberColumn:SetHeight(maxHeight)
				mainDKPColumn:SetHeight(maxHeight)
				alternateNumberColumn:SetHeight(maxHeight)
				alternateDKPColumn:SetHeight(maxHeight)
				eventNameColumn:SetCallback("OnEnter", showHighlight)
				timeColumn:SetCallback("OnEnter", showHighlight)
				mainNumberColumn:SetCallback("OnEnter", showHighlight)
				mainDKPColumn:SetCallback("OnEnter", showHighlight)
				alternateNumberColumn:SetCallback("OnEnter", showHighlight)
				alternateDKPColumn:SetCallback("OnEnter", showHighlight)
				eventNameColumn:SetCallback("OnLeave", hideHighlight)
				timeColumn:SetCallback("OnLeave", hideHighlight)
				mainNumberColumn:SetCallback("OnLeave", hideHighlight)
				mainDKPColumn:SetCallback("OnLeave", hideHighlight)
				alternateNumberColumn:SetCallback("OnLeave", hideHighlight)
				alternateDKPColumn:SetCallback("OnLeave", hideHighlight)
				self:SetHelp(eventNameColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
				self:SetHelp(timeColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
				self:SetHelp(mainNumberColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
				self:SetHelp(mainDKPColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
				self:SetHelp(alternateNumberColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
				self:SetHelp(alternateDKPColumn, L["Left click to edit this event, CTRL + Left click to delete this event."])
			end
			mainFrame.addKillsButton:SetDisabled(not raid["start"] or raid["finish"])
			mainFrame.addRewardsAndPunishmentsButton:SetDisabled(not raid["start"] or raid["finish"])
		elseif raidInfoGroup == "members" then
			mainFrame.memberListScrollFrame:ReleaseChildren()
			mainFrame.importButton:SetDisabled(not raid["start"] or raid["finish"])
			for name, member in pairs(raid["members"]) do
				local sg = AceGUI:Create("SimpleGroup")
				sg:SetLayout("Flow")
				sg:SetFullWidth(true)
				local nameColumn = AceGUI:Create("InteractiveLabel")
				nameColumn:SetText(name)
				nameColumn:SetWidth(110)
				nameColumn:SetHighlight(0.4,0.4,0.4,0.4)
				sg:AddChild(nameColumn)
				local classColumn = AceGUI:Create("InteractiveLabel")
				classColumn:SetText(L[member["class"]])
				classColumn:SetWidth(80)
				classColumn:SetHighlight(0.4,0.4,0.4,0.4)
				sg:AddChild(classColumn)
				local joinTimeColumn = AceGUI:Create("InteractiveLabel")
				joinTimeColumn:SetText(date(TIME_FORMAT, member["joinTime"]))
				joinTimeColumn:SetWidth(80)
				joinTimeColumn:SetHighlight(0.4,0.4,0.4,0.4)
				sg:AddChild(joinTimeColumn)
				local leaveTimeColumn = AceGUI:Create("InteractiveLabel")
				if member["leaveTime"] then
					leaveTimeColumn:SetText(date(TIME_FORMAT, member["leaveTime"]))
				end
				leaveTimeColumn:SetWidth(80)
				leaveTimeColumn:SetHighlight(0.4,0.4,0.4,0.4)
				sg:AddChild(leaveTimeColumn)
				local inRaidColumn = AceGUI:Create("InteractiveLabel")
				inRaidColumn:SetWidth(50)
				if UnitInRaid(name) then
					inRaidColumn:SetText(YES)
				else
					inRaidColumn:SetText(NO)
				end
				if UnitInRaid(name) and member["online"] then
					nameColumn:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
					classColumn:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
					joinTimeColumn:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
					leaveTimeColumn:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
					inRaidColumn:SetColor(RAID_CLASS_COLORS[member["class"]].r, RAID_CLASS_COLORS[member["class"]].g, RAID_CLASS_COLORS[member["class"]].b)
				else
					nameColumn:SetColor(0.4, 0.4, 0.4)
					classColumn:SetColor(0.4, 0.4, 0.4)
					joinTimeColumn:SetColor(0.4, 0.4, 0.4)
					leaveTimeColumn:SetColor(0.4, 0.4, 0.4)
					inRaidColumn:SetColor(0.4, 0.4, 0.4)
				end
				inRaidColumn:SetHighlight(0.4,0.4,0.4,0.4)
				sg:AddChild(inRaidColumn)
				
				local maxHeight = max(nameColumn.frame:GetHeight(), classColumn.frame:GetHeight(), joinTimeColumn.frame:GetHeight(), leaveTimeColumn.frame:GetHeight(), inRaidColumn.frame:GetHeight())
				nameColumn:SetHeight(maxHeight)
				classColumn:SetHeight(maxHeight)
				joinTimeColumn:SetHeight(maxHeight)
				leaveTimeColumn:SetHeight(maxHeight)
				inRaidColumn:SetHeight(maxHeight)
				local showHighlight = function()
					nameColumn.highlight:Show()
					classColumn.highlight:Show()
					joinTimeColumn.highlight:Show()
					leaveTimeColumn.highlight:Show()
					inRaidColumn.highlight:Show()
				end
				local hideHighlight = function()
					nameColumn.highlight:Hide()
					classColumn.highlight:Hide()
					joinTimeColumn.highlight:Hide()
					leaveTimeColumn.highlight:Hide()
					inRaidColumn.highlight:Hide()
				end
				nameColumn:SetCallback("OnEnter", showHighlight)
				classColumn:SetCallback("OnEnter", showHighlight)
				joinTimeColumn:SetCallback("OnEnter", showHighlight)
				leaveTimeColumn:SetCallback("OnEnter", showHighlight)
				inRaidColumn:SetCallback("OnEnter", showHighlight)
				nameColumn:SetCallback("OnLeave", hideHighlight)
				classColumn:SetCallback("OnLeave", hideHighlight)
				joinTimeColumn:SetCallback("OnLeave", hideHighlight)
				leaveTimeColumn:SetCallback("OnLeave", hideHighlight)
				inRaidColumn:SetCallback("OnLeave", hideHighlight)
				mainFrame.memberListScrollFrame:AddChild(sg)
			end
		elseif raidInfoGroup == "items" then
			mainFrame.addLootButton:SetDisabled(not raid["start"] or raid["finish"])
			mainFrame.lootedItemListScrollFrame:ReleaseChildren()
			for i, item in ipairs(raid["loots"]) do
				local _, itemLink = GetItemInfo(item["id"])
				local sg = AceGUI:Create("SimpleGroup")
				sg:SetLayout("Flow")
				sg:SetFullWidth(true)
				local itemColumn = AceGUI:Create("InteractiveLabel")
				itemColumn:SetWidth(150)
				itemColumn:SetText(itemLink)
				itemColumn:SetHighlight(0.4,0.4,0.4,0.4)
				itemColumn:SetUserData("item", item)
				sg:AddChild(itemColumn)
				local lootTimeColumn = AceGUI:Create("InteractiveLabel")
				lootTimeColumn:SetWidth(100)
				lootTimeColumn:SetText(date(TIME_FORMAT, item["time"]))
				lootTimeColumn:SetHighlight(0.4,0.4,0.4,0.4)
				lootTimeColumn:SetUserData("item", item)
				sg:AddChild(lootTimeColumn)
				local looterColumn = AceGUI:Create("InteractiveLabel")
				looterColumn:SetWidth(100)
				looterColumn:SetText(item["member"])
				local class = raid["members"][item["member"]]["class"]
				looterColumn:SetColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
				looterColumn:SetHighlight(0.4,0.4,0.4,0.4)
				looterColumn:SetUserData("item", item)
				sg:AddChild(looterColumn)
				local dkpColumn = AceGUI:Create("InteractiveLabel")
				dkpColumn:SetWidth(60)
				dkpColumn:SetHighlight(0.4,0.4,0.4,0.4)
				dkpColumn:SetUserData("item", item)
				sg:AddChild(dkpColumn)
				if item["resolve"] then
					dkpColumn:SetText(L["Resolve"])
					dkpColumn:SetColor(0.8, 0, 0)
				elseif item["storage"] then
					dkpColumn:SetText(L["Storage"])
					dkpColumn:SetColor(0.8, 0.8, 0.2)
				elseif item["cancel"] then
					dkpColumn:SetText(L["Cancel"])
					dkpColumn:SetColor(0.5, 0.5, 1)
				else
					dkpColumn:SetText(item["dkp"])
					dkpColumn:SetColor(0, 0.8, 0)
				end
				mainFrame.lootedItemListScrollFrame:AddChild(sg)
				local showHighlight = function()
					itemColumn.highlight:Show()
					lootTimeColumn.highlight:Show()
					looterColumn.highlight:Show()
					dkpColumn.highlight:Show()
				end
				local hideHighlight = function()
					itemColumn.highlight:Hide()
					lootTimeColumn.highlight:Hide()
					looterColumn.highlight:Hide()
					dkpColumn.highlight:Hide()
				end
				local maxHeight = max(itemColumn.frame:GetHeight(), lootTimeColumn.frame:GetHeight(), looterColumn.frame:GetHeight(), dkpColumn.frame:GetHeight())
				itemColumn:SetHeight(maxHeight)
				lootTimeColumn:SetHeight(maxHeight)
				looterColumn:SetHeight(maxHeight)
				dkpColumn:SetHeight(maxHeight)
				local OnItemClicked = function(widget, event, button)
					item = widget:GetUserData("item");
					local _, itemLink = GetItemInfo(item["id"])
					if item then
						if IsControlKeyDown() then
							selectedItem = item
							_G.StaticPopupDialogs["DCRTDeleteItemDialog"]["text"] = format(L["Are you sure to delte the %s recode?"], itemLink)
							_G.StaticPopup_Show("DCRTDeleteItemDialog")
							return
						end
						local itemFrame = AceGUI:Create("Frame")
						itemFrame.frame:SetResizable(false)
						itemFrame.sizer_se:Hide()
						itemFrame.sizer_s:Hide()
						itemFrame.sizer_e:Hide()
						itemFrame.closebutton:Hide()
						itemFrame.statusbg:Hide()
						itemFrame:SetHeight(110)
						itemFrame:SetWidth(600)
						itemFrame:SetLayout("List")
						itemFrame:SetTitle(L["Set DKP"])
						local labelPanel = AceGUI:Create("SimpleGroup")
						labelPanel:SetLayout("Flow")
						labelPanel:SetFullWidth(true)
						local nameLabel = AceGUI:Create("Label")
						nameLabel:SetText(item["member"])
						nameLabel:SetColor(RAID_CLASS_COLORS[raid["members"][item["member"]]["class"]].r, RAID_CLASS_COLORS[raid["members"][item["member"]]["class"]].g, RAID_CLASS_COLORS[raid["members"][item["member"]]["class"]].b)
						nameLabel:SetWidth(100)
						nameLabel.label:SetJustifyH("CENTER")
						labelPanel:AddChild(nameLabel)
						local label = AceGUI:Create("Label")
						label:SetText(format(L["looted item:%s, please set dkp for this tiem."], itemLink))
						label:SetWidth(400)
						labelPanel:AddChild(label)
						itemFrame:AddChild(labelPanel)
						local dkpEditBox = AceGUI:Create("EditBox")
						dkpEditBox.editbox:SetScript("OnEscapePressed",nil)
						dkpEditBox.editbox:SetScript("OnEnterPressed",nil)
						dkpEditBox.editbox:SetScript("OnTextChanged",nil)
						dkpEditBox.editbox:SetScript("OnReceiveDrag", nil)
						dkpEditBox.editbox:SetScript("OnMouseDown", nil)
						dkpEditBox.button:Hide()
						dkpEditBox:SetFullWidth(true)
						itemFrame:AddChild(dkpEditBox)
						local buttonPanel = AceGUI:Create("SimpleGroup")
						buttonPanel:PauseLayout()
						buttonPanel:SetFullWidth(true)
						local okButton = AceGUI:Create("Button")
						okButton:SetText(L["Okey"])
						okButton:SetWidth(100)
						buttonPanel:AddChild(okButton)
						okButton:SetPoint("TOPLEFT")
						okButton:SetCallback("OnClick", function(widget, event, button)
							local dkp = tonumber(dkpEditBox.editbox:GetText())
							if dkp then
								item["cancel"] = false
								item["resolve"] = false
								item["storage"] = false
								self:ItemDKPChanged(currentRaid, item, dkp)
								self:ShowRaidInfo(selectedRaid)
								itemFrame:Release()
							else
								self:PrintMessage("error", L["Score must be number"])
							end
						end)
						local cancelButton = AceGUI:Create("Button")
						cancelButton:SetText(L["Cancel"])
						cancelButton:SetWidth(100)
						buttonPanel:AddChild(cancelButton)
						cancelButton:SetPoint("TOPRIGHT")
						cancelButton:SetCallback("OnClick", function(widget, event, button) 
							self:ShowRaidInfo(selectedRaid)
							itemFrame:Release()
						end)
						local resolveButton = AceGUI:Create("Button")
						resolveButton:SetText(L["Resolve"])
						resolveButton:SetWidth(100)
						buttonPanel:AddChild(resolveButton)
						resolveButton:SetPoint("TOPRIGHT", cancelButton.frame, "TOPLEFT", -10, 0)
						resolveButton:SetCallback("OnClick", function(widget, event, button)
							item["cancel"] = false
							item["resolve"] = true
							item["storage"] = false
							self:SendMessage(format(L["Item %s has been resolved."], itemLink))
							self:ShowRaidInfo(selectedRaid)
							itemFrame:Release()
						end)
						local storageButton = AceGUI:Create("Button")
						storageButton:SetText(L["Storage"])
						storageButton:SetWidth(100)
						buttonPanel:AddChild(storageButton)
						storageButton:SetPoint("TOPRIGHT", resolveButton.frame, "TOPLEFT", -10, 0)
						storageButton:SetCallback("OnClick", function(widget, event, button)
							item["cancel"] = false
							item["resolve"] = false
							item["storage"] = true
							self:SendMessage(format(L["Item %s has been stored."], itemLink))
							self:ShowRaidInfo(selectedRaid)
							itemFrame:Release()
						end)
						itemFrame:AddChild(buttonPanel)
						itemFrame:Show()
						dkpEditBox:SetText(item["dkp"])
						dkpEditBox.editbox:SetFocus()
					end
				end
				itemColumn:SetCallback("OnEnter", showHighlight)
				lootTimeColumn:SetCallback("OnEnter", showHighlight)
				looterColumn:SetCallback("OnEnter", showHighlight)
				dkpColumn:SetCallback("OnEnter", showHighlight)
				itemColumn:SetCallback("OnLeave", hideHighlight)
				lootTimeColumn:SetCallback("OnLeave", hideHighlight)
				looterColumn:SetCallback("OnLeave", hideHighlight)
				dkpColumn:SetCallback("OnLeave", hideHighlight)
				itemColumn:SetCallback("OnClick", OnItemClicked)
				lootTimeColumn:SetCallback("OnClick", OnItemClicked)
				looterColumn:SetCallback("OnClick", OnItemClicked)
				dkpColumn:SetCallback("OnClick", OnItemClicked)
				self:SetHelp(itemColumn, L["Click to edit this item.Ctrl+Click to delete this item."])
				self:SetHelp(lootTimeColumn, L["Click to edit this item.Ctrl+Click to delete this item."])
				self:SetHelp(looterColumn, L["Click to edit this item.Ctrl+Click to delete this item."])
				self:SetHelp(dkpColumn, L["Click to edit this item.Ctrl+Click to delete this item."])
			end
		end
	else
		if raidInfoGroup == "info" then
			mainFrame.raidNameLabel:SetText(nil)
			mainFrame.creationTimeLabel:SetText(nil)
			mainFrame.startTimeLabel:SetText(nil)
			mainFrame.finishTimeLabel:SetText(nil)
			mainFrame.dkpSystemLabel:SetText(nil)
			mainFrame.musterScoreLabel:SetText(nil)
			mainFrame.dismissScoreLabel:SetText(nil)
			mainFrame.statusLabel:SetText(nil)
			mainFrame.startButton:SetDisabled(true)
			mainFrame.musterScoreButton:SetDisabled(true)
			mainFrame.pauseButton:SetDisabled(true)
			mainFrame.resumeButton:SetDisabled(true)
			mainFrame.dismissScoreButton:SetDisabled(true)
			mainFrame.finishButton:SetDisabled(true)
			mainFrame.exportButton:SetDisabled(true)
		elseif raidInfoGroup == "events" then
			mainFrame.eventListScrollFrame:ReleaseChildren()
			mainFrame.addKillsButton:SetDisabled(true)
			mainFrame.addRewardsAndPunishmentsButton:SetDisabled(true)
		elseif raidInfoGroup == "members" then
			mainFrame.memberListScrollFrame:ReleaseChildren()
			mainFrame.importButton:SetDisabled(true)
		elseif raidInfoGroup == "items" then
			mainFrame.addLootButton:SetDisabled(true)
		end
	end
end

function addon:ChangeDKP(dkpSystem, member, dkp)
	if dkpSystem then
		local system = self.db.profile["dkp"]["list"][dkpSystem]
		if system and system["data"][member] then
			system["data"][member]["dkp"] = system["data"][member]["dkp"] + dkp
		end
	end
end

function addon:CheckBossKilled(boss)
	if boss then
		local killed = true
		for k, v in pairs(boss["kill"]) do
			for name, value in pairs(boss["kill"][k]) do
				killed = killed and value
			end
		end
		if killed then
			local dkp = 0
			local alternateDkp = 0
			local config = self.db.profile["raidConfigs"][currentRaid["raidName"]]
			if config then
				dkp = config["bossScore"]
				alternateDkp = config["alternateScore"]
			end
			self:CreateEvent(boss["name"], true, dkp, nil, true, alternateDkp, nil, format(L["<--%s--> has been killed."], boss["name"]), false, true, true)
		end
	end
end

function addon:AddItemLoot(raid, member, item)
	if raid and raid["members"][member] and item then
		local itemName, itemLink, itemQuality = GetItemInfo(item)
		local itemId = tonumber(select(3, itemLink:find("item:(%d+):")))
		if itemQuality >= self.db.profile["raidConfigs"][raid["raidName"]]["recordItemLevel"] then
			if not self.db.profile["items"][itemId] then
				self.db.profile["items"][itemId] = {
					["ignore"] = false
				}
			end
			if not self.db.profile["items"][itemId]["ignore"] then
				local lootedItem = {
					["time"] = time(),
					["member"] = member,
					["id"] = itemId,
					["dkp"] = 0,
					["resolve"] = false,
					["storage"] = false,
					["cancel"] = false
				}
				table.insert(raid["loots"], lootedItem)
				if self.db.profile["promptLootDialog"] then
					local itemFrame = AceGUI:Create("Frame")
					itemFrame.frame:SetResizable(false)
					itemFrame.sizer_se:Hide()
					itemFrame.sizer_s:Hide()
					itemFrame.sizer_e:Hide()
					itemFrame.closebutton:Hide()
					itemFrame.statusbg:Hide()
					itemFrame:SetHeight(110)
					itemFrame:SetWidth(600)
					itemFrame:SetLayout("List")
					itemFrame:SetTitle(L["Set DKP"])
					local labelPanel = AceGUI:Create("SimpleGroup")
					labelPanel:SetLayout("Flow")
					labelPanel:SetFullWidth(true)
					local nameLabel = AceGUI:Create("Label")
					nameLabel:SetText(lootedItem["member"])
					nameLabel:SetColor(RAID_CLASS_COLORS[raid["members"][member]["class"]].r, RAID_CLASS_COLORS[raid["members"][member]["class"]].g, RAID_CLASS_COLORS[raid["members"][member]["class"]].b)
					nameLabel:SetWidth(100)
					nameLabel.label:SetJustifyH("CENTER")
					labelPanel:AddChild(nameLabel)
					local label = AceGUI:Create("Label")
					label:SetText(format(L["looted item:%s, please set dkp for this tiem."], itemLink))
					label:SetWidth(400)
					labelPanel:AddChild(label)
					itemFrame:AddChild(labelPanel)
					local dkpEditBox = AceGUI:Create("EditBox")
					dkpEditBox.editbox:SetScript("OnEscapePressed",nil)
					dkpEditBox.editbox:SetScript("OnEnterPressed",nil)
					dkpEditBox.editbox:SetScript("OnTextChanged",nil)
					dkpEditBox.editbox:SetScript("OnReceiveDrag", nil)
					dkpEditBox.editbox:SetScript("OnMouseDown", nil)
					dkpEditBox.button:Hide()
					dkpEditBox:SetFullWidth(true)
					itemFrame:AddChild(dkpEditBox)
					local buttonPanel = AceGUI:Create("SimpleGroup")
					buttonPanel:PauseLayout()
					buttonPanel:SetFullWidth(true)
					local okButton = AceGUI:Create("Button")
					okButton:SetText(L["Okey"])
					okButton:SetWidth(100)
					buttonPanel:AddChild(okButton)
					okButton:SetPoint("TOPLEFT")
					okButton:SetCallback("OnClick", function(widget, event, button)
						local dkp = tonumber(dkpEditBox.editbox:GetText())
						if dkp then
							self:ItemDKPChanged(currentRaid, lootedItem, dkp)
							itemFrame:Release()
						else
							self:PrintMessage("error", L["Score must be number"])
						end
					end)
					local cancelButton = AceGUI:Create("Button")
					cancelButton:SetText(L["Cancel"])
					cancelButton:SetWidth(100)
					buttonPanel:AddChild(cancelButton)
					cancelButton:SetPoint("TOPRIGHT")
					cancelButton:SetCallback("OnClick", function(widget, event, button) 
						lootedItem["cancel"] = true
						itemFrame:Release()
					end)
					local resolveButton = AceGUI:Create("Button")
					resolveButton:SetText(L["Resolve"])
					resolveButton:SetWidth(100)
					buttonPanel:AddChild(resolveButton)
					resolveButton:SetPoint("TOPRIGHT", cancelButton.frame, "TOPLEFT", -10, 0)
					resolveButton:SetCallback("OnClick", function(widget, event, button)
						lootedItem["resolve"] = true
						self:SendMessage(format(L["Item %s has been resolved."], itemLink))
						itemFrame:Release()
					end)
					local storageButton = AceGUI:Create("Button")
					storageButton:SetText(L["Storage"])
					storageButton:SetWidth(100)
					buttonPanel:AddChild(storageButton)
					storageButton:SetPoint("TOPRIGHT", resolveButton.frame, "TOPLEFT", -10, 0)
					storageButton:SetCallback("OnClick", function(widget, event, button)
						lootedItem["storage"] = true
						self:SendMessage(format(L["Item %s has been stored."], itemLink))
						itemFrame:Release()
					end)
					itemFrame:AddChild(buttonPanel)
					itemFrame:Show()
					dkpEditBox:SetText(lootedItem["dkp"])
					dkpEditBox.editbox:SetFocus()
				end
			end
		end
	end
end

function addon:ItemDKPChanged(raid, item, dkp)
	if raid then
		self:ChangeDKP(raid["dkpSystem"], item["member"], item["dkp"])
		self:ChangeDKP(raid["dkpSystem"], item["member"], -dkp)
		item["dkp"] = dkp
		local itemLink = select(2, GetItemInfo(item["id"]))
		self:SendMessage(format(L["%s looted %s, deduct %s DKP."], item["member"], itemLink, item["dkp"]))
		self:SendMessage(format(L["You looted %s, deduct %s DKP."], itemLink, item["dkp"]), item["member"])
	end
end

function addon:DeleteItem(raid, item)
	if raid then
		for i, v in ipairs(raid["loots"]) do
			if v == item then
				tremove(raid["loots"], i)
			end
		end
	end
end

function addon:ShowMainFrame()
	if not mainFrame then
		self:CreateMainFrame()
	end
	mainFrame:Show()
end

function addon:HideMainFrame()
	if mainFrame then
		mainFrame:Hide()
		mainFrame = nil
	end
end
--Events
function addon:OnInitialize()
	local oldfunc = ChatFrame_OnEvent
	ChatFrame_OnEvent = function(self, event, ...)
		local txt = select(1, ...) or ""
		if event == "CHAT_MSG_WHISPER_INFORM" and (strfind(txt, L["--------DCRT DKP query result---------"]) or strfind(txt, L["-------------No data--------------"]) or strfind(txt, L["DCRT DKP Message:"])) then
			return
		end
		oldfunc(self, event, ...)
	end
	self.db = LibStub("AceDB-3.0"):New("DCRTDB", {profile = defaultConfigs}, "profile")
	DKPDataFormat["function"][self.db.profile["dkpDataFormat"]]()
	self:RegisterChatCommand("dcrt", function()
		if mainFrame then
			self:HideMainFrame()
		else
			self:ShowMainFrame()
		end
	end)
end

function addon:OnEnable()
	for k, v in pairs(self.db.profile["raidList"]) do
		if not v["finish"] then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnLog")
			self:RegisterEvent("CHAT_MSG_LOOT", "OnItemLooted")
			currentRaid = v
			if currentRaid["start"] and not currentRaid["pause"] then
				currentTimer = self:ScheduleRepeatingTimer("OnTimer", 60)
			end
		end
	end
	self:InitComponents()
	
	self:RegisterEvent("CHAT_MSG_WHISPER", "OnReceiveWhisperMessage")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "OnMembersUpdate")
	self:RegisterEvent("PARTY_CONVERTED_TO_RAID", "OnMembersUpdate")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnMembersUpdate")
end

function addon:OnDisable()
	if currentRaid and currentRaid["start"] and not currentRaid["pause"] and currentTimer then
		self:CancelTimer(currentTimer)
		currentTimer = nil
	end
	self:UnregisterEvent("RAID_ROSTER_UPDATE")
	self:UnregisterEvent("PARTY_CONVERTED_TO_RAID")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function addon:OnTimer()
	if currentRaid and currentRaid["start"] and not currentRaid["pausse"] then
		for name, member in pairs(currentRaid["members"]) do
			if not self:IsBaned(name) then
				if self:IsMain(name) then
					member["activeMinutes"] = member["activeMinutes"] + 1
					if member["activeMinutes"] % 60 == 0 then
						self:ChangeDKP(currentRaid["dkpSystem"], name, self.db.profile["raidConfigs"][currentRaid["raidName"]]["timeScore"])
					end
				elseif self:IsAlternate(name) then
					member["alternateMinutes"] = member["alternateMinutes"] + 1
					if member["alternateMinutes"] % 60 == 0 then
						self:ChangeDKP(currentRaid["dkpSystem"], name, self.db.profile["raidConfigs"][currentRaid["raidName"]]["alternateTimeScore"])
					end
				end
			end
		end
	end
end

function addon:OnMembersUpdate()
	if mainFrame then
		mainFrame.newRaidButton:SetDisabled(currentRaid or GetRealNumRaidMembers() <= 0)
	end
	if currentRaid and currentRaid["start"] and not UnitInBattleground("player") then
		local num = GetRealNumRaidMembers()
		for u = 1, num do
			local name, _, subgroup, level, _, class, _, online = GetRaidRosterInfo(u)
			if name and not name:find("-") then
				local member = currentRaid["members"][name]
				if member == nil then
					member = {}
					member["name"] = name
					member["level"] = level
					member["sex"] = UnitSex(name) or 1
					member["class"] = class
					_, member["race"] = UnitRace(name) or "UNKNOW"
					member["joinTime"] = time()
					member["activeMinutes"] = 0
					member["alternateMinutes"] = 0
					currentRaid["members"][name] = member
					self:UpdateDKPList(currentRaid["dkpSystem"], name)
				end
				member["online"] = online
				member["subgroup"] = subgroup
			end
		end
		for _, p in pairs(currentRaid["members"]) do
			if not UnitInRaid(p["name"]) or not p["online"] then
				p["leaveTime"] = time()
			end
		end
	end
end

function addon:OnReceiveWhisperMessage(_, message, sender)
	if strupper(strtrim(message)) == strupper(self.db.profile["alternateOutofRaid"]["command"]) then
		self:AlternateOutofRaid(sender)
	end
	for k, v in pairs(self.db.profile["dkp"]["list"]) do
		local s, e = strfind(strupper(message), strupper(v["whisper"]))
		if s and e and s == 1 then
			local args = strsub(message, e + 1)
			local data = self:QueryDKP(sender, k, strtrim(args))
			self:SendDKPMessage(k, data, "WHISPER", sender)
		end
	end
end

function addon:OnLog(_, _, event, _, sourceName, _, _, destName)
	if currentRaid and currentRaid["start"] and not currentRaid["pause"] then
			for name, boss in pairs(currentRaid["bossMod"]) do
				if sourceName and boss["kill"]["UNIT_DIED"] and boss["kill"]["UNIT_DIED"][sourceName] then
					boss["kill"]["UNIT_DIED"][sourceName] = false
				end
			end
		if event == "UNIT_DIED" then
			for name, boss in pairs(currentRaid["bossMod"]) do
				if boss["kill"]["UNIT_DIED"] and boss["kill"]["UNIT_DIED"][destName] == false then
					boss["kill"]["UNIT_DIED"][destName] = true
					self:CheckBossKilled(boss)
				end
			end
		end
	end
end

function addon:OnItemLooted(_, msg)
	if currentRaid then
		local player, item, amount = deformat(msg, LOOT_ITEM)
		if not player or not item then
			player, item = deformat(msg, LOOT_ROLL_WON)
		end
		if player == YOU then
			player = UnitName("player")
		end
		if not player or not item then
			player, item, amount = deformat(msg, LOOT_ITEM_MULTIPLE)
		end
		if not item then
			item, amount = deformat(msg, LOOT_ITEM_SELF_MULTIPLE)
			player = UnitName("player")
		end
		if not amount then amount = 1 end
		if not item then return end
		self:AddItemLoot(currentRaid, player, item)
	end
end
