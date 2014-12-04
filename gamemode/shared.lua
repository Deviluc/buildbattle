GM.Name = "DevilMode"
GM.Author = "Deviluc"
GM.Email = "deviluc@googlemail.com"
GM.Website = "N/A"

DeriveGamemode( "sandbox" )

include("player_class/player_build.lua")
include("player_class/player_fight.lua")

local Mode = "build"
local chatCommands = {["!printMoney"] = printMoney, ["!setBuildMode"] = setBuildMode, ["!setFightMode"] = setFightMode, ["!copy"] = copy}
local duplicationBuffer = {}
local logLevel = 2

function GM:Initialize()
	createDB()	
end

function setLogLevel(ply, cmd, args)
	if table.Count(args) > 0 and ply:IsAdmin() then
		local number = tonumber(args[1], 10)
		
		if number then
			logLevel = number
		else
			log("Please enter a valid number!", 0)
		end
		
	else
		log("logLevel = " .. logLevel .. "\nUsage: logLevel number", 0)
	end
end

function log(text, level)
	
	if level and text then
		if logLevel >= level then
			print("[SERVER]", text)
		end
	else 
		log("Logging error...", 0)
		if not text then
			log("Text is null...", 0)
		end
	end
end

function sqlQuery(ply, cmd, args)
	if ply and args then
		if #args == 1 then
			result = sql.Query(args[1])
			
			if result then
				log(table.ToString(result), 0)
			end
		end
	end
end

function createDB()
	if not sql.TableExists("player_money") then
		sql.Query("CREATE TABLE player_money (SteamID string, Money int)")
	end
	
	if not sql.TableExists("prop_blacklist") then
		sql.Query("CREATE TABLE prop_blacklist (Model string)")
	end
	
	if not sql.TableExists("duplications") then
		sql.Query("CREATE TABLE duplications (ID int, Name string, Price int, OwnerSteamID string, Data string)")
	end
	
end

function getOwner(entity)
	local players = player.GetAll()
	
	print("Seraching owner...")
	log(table.ToString(players, "Players", true), 2)
	
	local i = 1
	
	while (i <= table.Count(players)) do
		log("Checking player: " .. players[i].GetName(), 2)
		if isOwner(players[i], entity) then
			log("Owner found!", 2)
			return players[i]
		end
		
		i = i + 1
	end
	
	if table.Count(players) < 1 then
		log("No players found...", 1)
	end
	
	return nil
end

function firstSpawn(ply)
	sql.Query("INSERT INTO player_money (SteamID, Money) VALUES ('" .. ply:SteamID() .. "', 0)")
	
	if Mode == "build" then
		setPlayerBuild(ply)
	elseif Mode == "fight" then
		setPlayerFight(ply)
	end
	
end

function getMoney(ply)
	return sql.QueryValue("SELECT Money FROM player_money WHERE SteamID='" .. ply:SteamID() .. "'")
end

function setMoney(ply, money)
	local success = sql.Query("UPDATE player_money SET Money=" .. money .. " WHERE SteamID='" .. ply:SteamID() .. "'")
	
	if success then
		log("Set money of player \"" .. ply:GetName() .. "\" to: " .. money, 2)
	else
		log("Error setting money of player \"" .. ply:GetName() .. "\"...")
	end
	
end

function printMoney(ply)
	print("Money: ", getMoney(ply))
end

function playerSpawn(ply)
	if Mode == "build" then
		ply:GodEnable()
	end
end

function playerNoclip(ply, state)
	if state then
		if Mode == "build" then
			return true
		else return false end
	end
end

function isOnBlackList(model)
	local blacklist = sql.Query("SELECT model FROM prop_blacklist WHERE Model='" .. model .. "'")
	
	if table.Count(blacklist) == 1 then
		return true
	else return false end
end

function setOnBlackList(model)
	if not isOnBlackList(model) then
		sql.Query("INSERT INTO prop_blacklist (Model) VALUES ('" .. model .. "')")
	end
end
	
	

function setBuildMode()
	Mode = "build"
	
	for k,v in pairs(player.GetAll()) do
		setPlayerBuild(ply)
	end
end

function setPlayerBuild(ply)
	if ply then 
		player_manager.SetPlayerClass(ply, "player_build")
	end
end


function setFightMode()
	Mode = "fight"
	
	for k,v in pairs(player.GetAll()) do
		setPlayerFight(ply)
	end
end

function setPlayerFight(ply)
	if ply then
		player_manager.SetPlayerClass(ply, "player_fight")
	end
end

function playerChat(ply, text, team)
	
	print("")

	if table.HasValue(table.GetKeys(chatCommands), text) then
		chatCommands[text](ply)
		return false
	else return text end
end

function playerKill(victim, inflictor, attacker)
	if mode == "fight" then
		log(attacker:Name() .. " killed " .. victim:Name() .. "!", 1)
		if not victim == attacker then
			local Money = getMoney(attacker)
			Money = Money + 10
			setMoney(attacker, money)
		end
	end
end

function getAvailableID(table_name)
	local id = sql.QueryValue("SELECT ID FROM " .. table_name .. " ORDER BY ID DESC", 1)
	
	if id then
		return id + 1
	else
		return 1
	end
	
end

function loadDuplication(ply)
	
	if ply then
		local resultSet = sql.Query("SELECT Name, Price, ID FROM duplications WHERE OwnerSteamID='" .. ply:SteamID() .. "'")
		ply:ConCommand("createLoadFrame \"Duplications\" \"Name\" \"Price\" \n")
		
		if resultSet then
			log(table.ToString(resultSet, " Saved duplications", true), 1)
			
			
			
			local i = 1
			
			while (i <= table.Count(resultSet)) do
				log(table.ToString(table.GetKeys(resultSet), "Keys", true), 2)
				local command = "addLoadFrameEntry \"" .. resultSet[i].Name .. "\" \"" .. resultSet[i].Price .. "\" \"" .. resultSet[i].ID .. "\""
				log("Command: " .. command, 2)
				ply:ConCommand(command)
				i = i + 1
			end 
		else 
			log("No duplications...", 1)
		end
		
	end
end

function paste(ply, cmd, args)
	
	if ply and args then
		if table.Count(args) == 1 then
			local query = "SELECT Data FROM duplications WHERE ID=" .. args[1]
			-- Add  (.. " AND OwnerSteamID='" .. ply:SteamID() .. "'") for multiplayer
			log("Query: " .. query, 2)
			local result = sql.Query(query)
			
			if result then
				local json = result[1].Data
				if json then
					log("Json data:\n" .. json, 2)
					
					local duplication = util.JSONToTable(json)
					
					log(table.ToString(duplication, "Duplication", true), 2)
					
					duplicator.Paste(ply, duplication.Entities, duplication.Constraints)
					
				end
			else
				log("Sql-Query failed!", 2)
			end
		else
			log("Check arguments!", 2)
			log(table.ToString(args, "Arguments", true), 2)
		end
	end
end

function saveDuplication(ply, cmd, args)

	log("Saving duplication...", 1)
	
	local name = args[1]
	local price = tonumber(args[2])
	local dupeID = tonumber(args[3])

	
	if price and name and ply and dupeID then
		local query = "INSERT INTO duplications (ID, Name, Price, OwnerSteamID, Data) VALUES (" .. dupeID .. ", '" .. name .. "', " .. price .. ", '" .. ply:SteamID() .. "', '" .. duplicationBuffer[dupeID] .."')"
		log("Query: " .. query, 2)
		local success = sql.Query(query)
		table.remove(duplicationBuffer, dupeID)
		if success then
			log("Query returned: " .. table.ToString(success), 2)
		end
	else
		log("Error, check arguments...", 1)
		log(table.ToString(args, "Arguments", true), 1)
	end
	
end
	
function copy(ply)
	local entity = ply:GetEyeTrace().Entity
	
	if entity then
		log("Player: " .. ply:GetName(), 1)
		log("Entity: " .. entity:GetModel(), 1)
		
		if not entity:IsWorld() then
			log("Entity not world...", 1)
			if isOwner(ply, entity) then
				local localPos = ply:WorldToLocal(entity:GetPos())
				duplicator.SetLocalPos(localPos)
				local duplication = duplicator.Copy(entity)
				
				duplicator.SetLocalPos(Vector(0, 0, 0))
				
				log(table.ToString(duplication, "Duplication", true), 2)
				local json = util.TableToJSON(duplication, false)
				
				log("Json data:\n" .. json, 2)
				
				json = SQLStr(json, true)
				
				local dupeID = getAvailableID("duplications")
				duplicationBuffer[dupeID] = json
				
				
				
				ply:ConCommand("openSaveGUI \"" .. dupeID .. "\"\n")
				
			else 
				log("Ownercheck failed!")
			end
		end
	elseif ply then
		log("Player: " .. ply:GetName(), 1)
		log("No entity selected or no owner found...", 1)
	end
end

		

concommand.Add("printMoney", printMoney)
concommand.Add("setBuildMode", setBuildMode)
concommand.Add("setFightMode", setFightMode)
concommand.Add("copy", copy)
concommand.Add("saveDuplication", saveDuplication)
concommand.Add("loadDuplication", loadDuplication)
concommand.Add("logLevel", setLogLevel)
concommand.Add("paste", paste)
concommand.Add("sqlQuery", sqlQuery)
hook.Add("PlayerInitialSpawn", "AddDB", firstSpawn)
hook.Add("PlayerSpawn", "Spawn", playerSpawn)
hook.Add("PlayerNoClip", "NoClip", playerNoclip)
hook.Add("PlayerSay", "PlayerChat", playerChat)
hook.Add("PlayerDeath", "PlayerDeath", playerKill)