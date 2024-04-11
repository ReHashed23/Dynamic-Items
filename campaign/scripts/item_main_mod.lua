-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local tRaces = {
	"Dwarf",
	"Elf",
	"Gnome",
	"Halfling",
	"Half-Elf",
	"Half-Orc",
	"Dragonborn",
	"Human",
	"Human-Variant",
	"Tiefling",
	"Aasimar",
	"Bugbear",
	"Centaur",
	"Changeling",
	"Fairy",
	"FirBolg",
	"Githyanki",
	"Githzerai",
	"Goblin",
	"Goliath",
	"Harengon",
	"Hobgoblin",
	"Kalashtar",
	"Kenku",
	"Kobold",
	"Lizardfolk",
	"Loxodon",
	"Minotaur",
	"Orc",
	"Shifter",
	"Tabaxi",
	"Tiefling-Variant",
	"Tortle"
};
local tEffectTags = {
	"INIT",
	"ATK",
	"AC",
	"CRIT",
	"DMG",
	"HEAL",
	"SAVE",
	"SKILL",
	"CHECK",
	"STR",
	"DEX",
	"CON",
	"INT",
	"WIS",
	"CHA",
	"DMGTYPE",
	"DMGO",
	"REGEN",
	"IMMUNE",
	"RESIST",
	"VULN",
	"COVER",
	"SCOVER",
	"ADVINIT",
	"DISINIT",
	"ADVATK",
	"DISATK",
	"GRANTADVATK",
	"GRANTDISATK",
	"ADVSAV",
	"DISSAV",
	"ADVCHK",
	"DISCHK",
	"ADVSKILL",
	"DISSKILL",
	"ADVDEATH",
	"DISDEATH",
};
local tDurTags = {
	"minute",
	"hour",
	"day",
	"rnd"
};

local tEffectsToProcess = {};

function onInit()
	self.update();
end

function VisDataCleared()
	self.update();
end

function InvisDataAdded()
	self.update();
end

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end

function updateControl(sControl, bReadOnly, bID)
	if not self[sControl] then
		return false;
	end
		
	if not bID then
		return self[sControl].update(bReadOnly, true);
	end
	
	return self[sControl].update(bReadOnly);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);
	
	local bWeapon = ItemManager.isWeapon(nodeRecord);
	local bArmor = ItemManager.isArmor(nodeRecord);
	local sTypeLower = StringManager.trim(DB.getValue(nodeRecord, "type", "")):lower();
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
	local bVehicleComponent = (sTypeLower == "vehicle component");
	local bLegacyVehicle = (sTypeLower == "waterborne vehicles") or (sTypeLower == "mounts and other animals");
	
	local bSection1 = false;
	if Session.IsHost then
		if self.updateControl("nonid_name", bReadOnly, true) then bSection1 = true; end;
	else
		self.updateControl("nonid_name", false);
	end
	if (Session.IsHost or not bID) then
		if self.updateControl("nonidentified", bReadOnly, true) then bSection1 = true; end;
	else
		self.updateControl("nonidentified", false);
	end

	local bSection2 = false;
	if self.updateControl("type", bReadOnly, bID) then bSection2 = true; end
	if self.updateControl("subtype", bReadOnly, bID) then bSection2 = true; end
	if self.updateControl("rarity", bReadOnly, bID and not bVehicleComponent) then bSection2 = true; end
	
	local bSection3 = false;
	if self.updateControl("cost", bReadOnly, bID) then bSection3 = true; end
	if self.updateControl("weight", bReadOnly, bID and not bVehicleComponent) then bSection3 = true; end

	local bSection4 = true;
	if Session.IsHost or bID then 
		if bWeapon then
			type_stats.setValue("item_main_weapon", nodeRecord);
		elseif bArmor then
			type_stats.setValue("item_main_armor", nodeRecord);
		elseif bArcaneFocus then
			type_stats.setValue("item_main_arcanefocus", nodeRecord);
		elseif bVehicleComponent then
			type_stats.setValue("item_main_vehicle", nodeRecord);
		elseif bLegacyVehicle then
			type_stats.setValue("item_main_vehicle_legacy", nodeRecord);
		else
			type_stats.setValue("", "");
			bSection4 = false;
		end
	else
		type_stats.setValue("", "");
		bSection4 = false;
	end
	type_stats.update(bReadOnly, bID);

	-- if DB.getPath(nodeRecord):match("charsheet") then
	self.updateCharSentItem(nodeRecord, bID);
	-- end
	
	local bSection5 = false;
	if bReadOnly then
		description.setVisible(bID and not description.isEmpty());
		bSection5 = (description.isVisible())
	else
		description.setVisible(true);
		bSection5 = true;
	end
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
	divider4.setVisible((bSection1 or bSection2 or bSection3 or bSection4) and bSection5);

	if Session.IsHost or bID then 
		if ItemManager.isPack(nodeRecord) then
			type_lists.setValue("item_main_subitems", nodeRecord);
		elseif bVehicleComponent then
			type_lists.setValue("item_main_vehicle_actions", nodeRecord);
		else
			type_lists.setValue("", "");
		end
	else
		type_lists.setValue("", "");
	end
	type_lists.update(bReadOnly);
end

function updateCharSentItem(nodeRecord, bID)
	local nodeChar = DB.getChild(nodeRecord, "...");
	local sItemName = DB.getValue(nodeRecord, "name");
	local sRacialDescription = "";
	local bRaceMet = false;
	local bRacePresent = false;
	local sClassDescription = "";
	local bClassMet = false;
	local bClassPresent = false;
	local sLevelDescription = "";
	local bLevelMet = false;
	local bLevelPresent = false;
	local sLevel2Description = "";
	local bLevel2Met = false;
	local bLevel2Present = false;
	local sLevel3Description = "";
	local bLevel3Met = false;
	local bLevel3Present = false;
	local sAlignmentDescription = "";
	local bAlignmentMet = false;
	local bAlignmentPresent = false; 
	local bCursePresent = false; 
	local sCurseDescription = "";
	local sItemBaseDescription = "";
	local tExtensionsLoaded = Extension.getExtensions();
	local eAdvancedEffects;
	for _, vExtension in pairs(tExtensionsLoaded) do
		local sPath = DB.getPath(vExtension);
		if StringManager.contains({"advancedeffects"},sPath:lower()) then
			eAdvancedEffects = vExtension;
			bAELoaded = true;
		end
	end
	-- Collect Character's Items
	for _,vItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if nodeRecord == vItem then
			local sItemPath = DB.getPath(vItem);
			if DB.getValue(vItem, "descriptionRef") == nil then
				DB.copyNode(sItemPath .. ".description", sItemPath .. ".descriptionRef");
			end
			local sDescRef = DB.getValue(vItem, "descriptionRef");
			if User.isHost() == true then
				DB.setValue(vItem, "description", "formattedtext", DB.getValue(vItem, "descriptionRef"));
				return;
			end
			local aSplit = StringManager.split(sDescRef, "~");
			for _,vItemDescription in ipairs(aSplit) do
				if vItemDescription:find("Race") then
					bRacePresent, bRaceMet, sRacialDescription = self.collectSentItemRaceFilter(vItem, nodeChar, bID, vItemDescription, DB.getValue(nodeChar, "race"));
				elseif vItemDescription:find("Class:") then
					local tClasses = DB.getChildList(nodeChar, "classes");
					bClassPresent, bClassMet, sClassDescription = self.collectSentItemClassFilter(vItem, nodeChar, bID, vItemDescription, tClasses, bRacePresent);
				elseif vItemDescription:find("Level:") then
					bLevelPresent, bLevelMet, sLevelDescription = self.collectSentItemLevelFilter(vItem, nodeChar, bID, vItemDescription, DB.getValue(nodeChar, "level"), bRacePresent, bClassPresent);
				elseif vItemDescription:find("Level2:") then
					bLevel2Present, bLevel2Met, sLevel2Description = self.collectSentItemLevel2Filter(vItem, nodeChar, bID, vItemDescription, DB.getValue(nodeChar, "level"), bRacePresent, bClassPresent, bLevelMet);
				elseif vItemDescription:find("Level3:") then
					bLevel3Present, bLevel3Met, sLevel3Description = self.collectSentItemLevel3Filter(vItem, nodeChar, bID, vItemDescription, DB.getValue(nodeChar, "level"), bRacePresent, bClassPresent, bLevel2Met);
				elseif vItemDescription:find("Alignment") then
					bAlignmentPresent, bAlignmentMet, sAlignmentDescription = self.collectSentItemAlignmentFilter(vItem, nodeChar, bID, vItemDescription, DB.getValue(nodeChar, "alignment"), bRacePresent, bClassPresent, bLevel1Present, bLevel2Present, bLevel3Present);
				elseif vItemDescription:find("Curse") then
					bCursePresent, sCurseDescription = self.collectSentCursedFilter(vItem, nodeChar, bID, vItemDescription);
				elseif vItemDescription:find("Base") then
					sItemBaseDescription = self.collectSentItemBaseFilter(vItem, nodeChar, bID, vItemDescription);
				else
					sItemBaseDescription = vItemDescription;
				end
			end
			if bID then
				if bRaceMet == true and bClassMet == false and bLevelMet == false and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == false and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == false and bLevelMet == false and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == true and bClassMet == true and bLevelMet == false and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sRacialDescription .. "</p>" .. sClassDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == false and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == true and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sClassDescription .. "</p>" .. sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. sLevel2Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == false and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. sLevel2Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == true and bLevel2Met == true and bLevel3Met == true and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sLevelDescription .. sLevel2Description .. sLevel3Description .. "</p>" .. sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == false and bAlignmentMet == true then
					DB.setValue(vItem, "description", "formattedtext", sAlignmentDescription .. "</p>" .. sItemBaseDescription);
				elseif bRaceMet == false and bClassMet == false and bLevelMet == false and bAlignmentMet == false then
					DB.setValue(vItem, "description", "formattedtext", sItemBaseDescription);
				end
			else 
				DB.setValue(vItem, "description", "formattedtext", sItemBaseDescription) 
			end
			local tEffectsToProcessCopy = tEffectsToProcess;
			for iIndex, vEffect in pairs(tEffectsToProcessCopy) do
				table.remove(tEffectsToProcess, iIndex);
			end
		end
	end
end

function collectSentItemRaceFilter(vItem, nodeChar, bID, s, sUserRace)
	local sRace1, sRace2 = s:match("Race: (%a+) (%a+)");
	if sRace1 == nil then
		sRace1 = s:match("Race: (%a+)");
	end
	local bRacePresent = false;
	local bRaceMet = false;
	local sRacialDescription;
	local sRaceReq;
	if sRace2 ~= nil then
		sRaceReq = race1 .. " " .. race2;
	else
		sRaceReq = race1;
	end
	for _, vRace in pairs(tRaces) do
		if sUserRace:match(vRace) then
			sUserRace = vRace;
		end
	end
	if sRaceReq ~= nil then
		bRacePresent = true;
		if sRace2 ~= nil then
			if (sRaceReq == sUserRace) or (sRace1 == sUserRace) or
				(sRace2 == sUserRace) then

				bRaceMet = true;
				racialDescription = s;
			end
		else
			if sRaceReq == sUserRace then
				bRaceMet = true;
				sRacialDescription = s;
			end
		end
	end
	if bRaceMet and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sRacialDescription);
	end
	return bRacePresent, bRaceMet, sRacialDescription;
end

function collectSentItemClassFilter(vItem, nodeChar, bID, s, tClasses, bRacePresent)
	local sUserClass;
	local bClassPresent = false;
	local bClassMet = false;
	local sClassDescription = "";
	if #tClasses > 0 then
		for _, vClass in ipairs(tClasses) do
			sUserClass = DB.getValue(vClass, "name", "");
			local sClass1, sClass2 = s:match("Class: (%a+) (%a+)");
			if sClass1 == nil then
				sClass1 = s:match("Class: (%a+)");
			end
			local tClassReq = {};
			if sClass1 then
				table.insert(tClassReq, sClass1);
				bClassPresent = true;

				if sClass2 then
					table.insert(tClassReq, sClass2);
				end
				for _,vClass in ipairs(tClassReq) do
					if vClass == sUserClass then
						bClassMet = true;
						if bRacePresent then
							sClassDescription = s:sub(5);
						else
							sClassDescription = s;
						end
					end
				end
			end
		end
	end
	if bClassMet and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sClassDescription);
	end
	return bClassPresent, bClassMet, sClassDescription;
end

function collectSentItemLevelFilter(vItem, nodeChar, bID, s, iLevel, bRacePresent, bClassPresent)
	local iLevelReq = tonumber(s:match("Level: (%d+)"));
	local bLevelPresent = false;
	local bLevelMet = false;
	local sLevelDescription;
	if iLevelReq ~= nil then
		bLevelPresent = true;
		if iLevelReq <= iLevel then
			bLevelMet = true;
			if bClassPresent or bRacePresent then
				sLevelDescription = s:sub(5);
			else
				sLevelDescription = s
			end
		end
	end
	if bLevelMet and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sLevelDescription);
	end
	return bLevelPresent, bLevelMet, sLevelDescription;
end

function collectSentItemLevel2Filter(vItem, nodeChar, bID, s, iLevel, bRacePresent, bClassPresent, bLevel1Met)
	local iLevel2Req = tonumber(s:match("Level2: (%d+)"));
	local bLevel2Present = false;
	local bLevel2Met = false;
	local sLevel2Description;
	if iLevel2Req ~= nil and bLevel1Met then
		bLevel2Present = true;
		if iLevel2Req <= iLevel then
			bLevel2Met = true;
			if bClassPresent or bRacePresent then
				sLevel2Description = s:sub(5);
			else
				sLevel2Description = s
			end
		end
	end
	if bLevel2Met and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sLevel2Description);
	end
	return bLevel2Present, bLevel2Met, sLevel2Description;
end

function collectSentItemLevel3Filter(vItem, nodeChar, bID, s, iLevel, bRacePresent, bClassPresent, bLevel2Met)
	local iLevel3Req = tonumber(s:match("Level3: (%d+)"));
	local bLevel3Present = false;
	local bLevel3Met = false;
	local sLevel3Description;
	if iLevel3Req ~= nil and bLevel2Met then
		bLevel3Present = true;
		if iLevel3Req <= iLevel then
			bLevel3Met = true;
			if bClassPresent or bRacePresent then
				sLevel3Description = s:sub(5);
			else
				sLevel3Description = s
			end
		end
	end
	if bLevel3Met and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sLevel3Description);
	end
	return bLevel3Present, bLevel3Met, sLevel3Description;
end

function collectSentItemAlignmentFilter(vItem, nodeChar, bID, s, sAlignment, bRacePresent, bClassPresent, bLevelPresent, bLevel2Present, bLevel3Present)
	local sAlignmentReq = s:match("Alignment: (%a+)");
	local bAlignmentMet = false;
	local bAlignmentPresent = false;
	if sAlignmentReq then
		bAlignmentPresent = true;
		if sAlignmentReq == sAlignment:upper() then
			if bClassPresent or bRacePresent or bLevelPresent or bLevel2Present or bLevel3Present then
				sAlignmentDescription = s:sub(5);
			else
				sAlignmentDescription = s;
			end
		end
	end
	if bAlignmentMet and bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sAlignmentDescription);
	end
	return bAlignmentPresent, bAlignmentMet, sAlignmentDescription;
end

function collectSentCursedFilter(vItem, nodeChar, bID, s, bRacePresent, bClassPresent, bLevelPresent, bLevel2Present, bLevel3Present, bAlignmentPresent)
	local sCurse = s:match("Curse"); 
	local bCursePresent = false;
	local sCurseDescription;
	if sCurse then 
		bCursePresent = true;
		if bClassPresent or bRacePresent  or bLevelPresent or bLevel2Present or bLevel3Present or bAlignmentPresent then
			sCurseDescription = s:sub(5);
		else
			sCurseDescription = s;
		end
	end
	if bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sCurseDescription);
	end
	return bCursePresent, sCurseDescription;
end

function collectSentItemBaseFilter(vItem, nodeChar, bID, s)
	local sBase = s:match("Base (%a+)"); 
	local sItemBaseDescription;
	if sBase then 
		if sBase == "Description" then 
			sItemBaseDescription = s:sub(5); 
		end
	end
	if bAELoaded and User.isHost() == false then
		self.AESynchronizer(vItem, nodeChar, sItemBaseDescription);
	end
	return sItemBaseDescription;
end

function AESynchronizer(nodeItem, nodeChar, sDescription)
	for _, vEffect in pairs(tEffectTags) do
		if sDescription:match("%f[%a]" .. vEffect .. "%f[%A]") then
			local nActionOnly;
			local sCompiledEffect;
			local nodeAEList = DB.getChild(nodeItem, "effectlist");
			local nodeCharEffectList = DB.getChild(nodeChar, "effectlist");
			local dDurationDice;
			local nDurationMod;
			local sVisibility;
			local nGMOnly;
			for _, vDurTag in pairs(tDurTags) do
				if sDescription:match("%f[%a]" .. vDurTag .. "%f[%A]") then
					sUnit = vDurTag;
					local sDurCatch = sDescription:match("Dice (%w+)");
					local sSetCatch = sDescription:match("Set (%w+)");
					if sDurCatch then
						dDurationDice = DiceManager.convertStringToDice(sDurCatch, true);
					else
						nDurationMod = tonumber(sSetCatch);
					end
				end
			end
			if sDescription:match("%f[%a]ActionOnly%f[%A]") then
				nActionOnly = 1;
			else
				nActionOnly = 0;
			end
			if sDescription:match("%f[%a]Curse%f[%A]") then
				sVisibility = "hide";
				nGMOnly = 1;
			else
				sVisibility = "show";
				nGMOnly = 0;
			end
			if dDurationDice and sUnit then
				local sEffectConstraint1, sEffectConstraint2, sEffectConstraint3 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
				if sEffectConstraint3 ~= nil then
					sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. " " .. sEffectConstraint3 .. "; [" .. DiceManager.convertDiceToString(dDurationDice) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
				else
					sEffectConstraint1, sEffectConstraint2 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
					if sEffectConstraint2 ~= nil then
						sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. "; [" .. DiceManager.convertDiceToString(dDurationDice) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
					elseif sEffectConstraint1 == nil then
						sEffectConstraint1 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+)");
						if sEffectConstraint1 == nil then
							sCompiledEffect = vEffect .. "; [" .. DiceManager.convertDiceToString(dDurationDice) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
						else
							sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. "; [" .. DiceManager.convertDiceToString(dDurationDice) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
						end
					end
				end
			elseif nDurationMod and sUnit then
				local sEffectConstraint1, sEffectConstraint2, sEffectConstraint3 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
				if sEffectConstraint3 ~= nil then
					sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. " " .. sEffectConstraint3 .. "; [" .. tostring(nDurationMod) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
				else
					sEffectConstraint1, sEffectConstraint2 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
					if sEffectConstraint2 ~= nil then
						sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. "; [" .. tostring(nDurationMod) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
					elseif sEffectConstraint1 == nil then
						sEffectConstraint1 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+)");
						if sEffectConstraint1 == nil then
							sCompiledEffect = vEffect .. "; [" .. tostring(nDurationMod) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
						else
							sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. "; [" .. tostring(nDurationMod) .. " " .. sUnit .. "] [" .. sVisibility .. "]";
						end
					end
				end
			elseif sUnit == nil then
				local sEffectConstraint1, sEffectConstraint2, sEffectConstraint3 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
				if sEffectConstraint3 ~= nil then
					sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. " " .. sEffectConstraint3 .. "; [" .. sVisibility .. "]";
				else
					sEffectConstraint1, sEffectConstraint2 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+) ([%+%-]?[%w%d]+)");
					if sEffectConstraint2 ~= nil then
						sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. " " .. sEffectConstraint2 .. "; [" .. sVisibility .. "]";
					elseif sEffectConstraint1 == nil then
						sEffectConstraint1 = sDescription:match("%f[%a]" .. vEffect .. "%f[%A]: ([%+%-]?[%w%d]+)");
						if sEffectConstraint1 == nil then
							sCompiledEffect = vEffect .. "; [" .. sVisibility .. "]";
						else
							sCompiledEffect = vEffect .. ": " .. sEffectConstraint1 .. "; [" .. sVisibility .. "]";
						end
					end
				end
			end
			local nodeEffect = DB.createChild(nodeAEList, vEffect);
			if nActionOnly == 1 then
				DB.setValue(nodeEffect, "effect", "string", sCompiledEffect .. " [ActionOnly]");
				DB.setValue(nodeEffect, "effect_description", "string", sCompiledEffect .. " [ActionOnly]");
			elseif nActionOnly == 0 then
				DB.setValue(nodeEffect, "effect", "string", sCompiledEffect);
				DB.setValue(nodeEffect, "effect_description", "string", sCompiledEffect);
			end
			DB.setValue(nodeEffect, "nInit", "number", 0);
			DB.setValue(nodeEffect, "source_name", "string", DB.getPath(nodeItem));
			DB.setValue(nodeEffect, "isgmonly", "number", nGMOnly);
			DB.setValue(nodeEffect, "sApply", "string", "");
			DB.setValue(nodeEffect, "sChangeState", "string", "");
			DB.setValue(nodeEffect, "isactive", "number", 1);
			DB.setValue(nodeEffect, "actiononly", "number", nActionOnly);
			DB.setValue(nodeEffect, "visibility", "string", sVisibility);
			if dDurationDice ~= nil then
				DB.setValue(nodeEffect, "durdice", "dice", dDurationDice);
				DB.setValue(nodeEffect, "durunit", "string", sUnit);
			end
			if nDurationMod ~= nil then
				DB.setValue(nodeEffect, "durmod", "number", nDurationMod);
				DB.setValue(nodeEffect, "durunit", "string", sUnit);
			end
			if DB.getChild(nodeCharEffectList, nodeEffect) == nil then
				EffectManagerADND.updateItemEffects(nodeItem);
				EffectManagerADND.updateCharEffects(nodeChar, nodeEffect);
			end
			dDurationDice = nil;
			nDurationMod = nil;
			sUnit = nil;
			sVisibility = nil;
		end
	end
end
