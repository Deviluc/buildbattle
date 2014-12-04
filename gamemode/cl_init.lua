include( "shared.lua" )

local loadFrame
local listView
local dupeIDs = {}

local logLevel = 1

function setLogLevel(ply, cmd, args)
	if table.Count(args) > 0 then
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
			print("[CLIENT]", text)
		end
	else 
		log("Logging error...", 0)
	end
end

function createWarning(text)
	local panel = vgui.Create("DFrame")
	panel:SetPos(50, 50)
	panel:SetSize(200, 175)
	panel:SetTitle("Warning")
	panel:ShowCloseButton(true)
	panel:SetDraggable(true)
	panel:SetVisible(true)
	
	local label = vgui.Create("DLabel")
	label:SetParent(panel)
	label:SetPos(10, 25)
	label:SetSize(180, 50)
	label:SetText(text)
	
	local button = vgui.Create("DButton")
	button:SetParent(panel)
	button:SetPos(100, 100)
	button:SetSize(100, 50)
	button:SetText("OK")
	
end

function createLoadFrame(ply, string, args)
	loadFrame = vgui.Create("DFrame")
	loadFrame:SetPos(50, 50)
	loadFrame:SetSize(200, 600)
	loadFrame:SetTitle(args[1])
	loadFrame:SetDraggable(true)
	loadFrame:ShowCloseButton(true)
	loadFrame:SetVisible(true)
	
	
	listView = vgui.Create( "DListView" )
	listView:SetParent(loadFrame)
	listView:SetSize(200, 400)
	listView:SetPos(0, 25)
	listView:SetMultiSelect(false)
	
	local i = 2
	
	dupeIDs = {}
	
	while (i <= table.Count(args)) do
		log("Argument: " .. args[i] .. " (i = " .. i .. ")", 1)
		listView:AddColumn(args[i])
		i = i + 1
	end
	
	local okButton = vgui.Create("DButton")
	okButton:SetParent(loadFrame)
	okButton:SetSize(75, 25)
	okButton:SetPos(115, 425)
	okButton:SetText("Paste")
	okButton.DoClick = function() 
		local selectedID = listView:GetSelectedLine()
		
		if selectedID then
			RunConsoleCommand("paste", dupeIDs[selectedID])
		else
			log("Nothing selected...", 2)
		end
	end
	
end

function addLoadFrameEntry(ply, string, args)	
	local lastID = table.Count(args)
	
	table.insert(dupeIDs, args[lastID])
	table.remove(args, lastID)
	listView:AddLine(unpack(args))
	
end

function createSaveFrame(ply, string, args)

	local dupeID = args[1]

	log("DupeID: " .. dupeID, 1)
				
	local panel = vgui.Create("DFrame")
	panel:SetPos(50, 50)
	panel:SetSize(200, 300)
	panel:SetTitle("Save Duplication")
	panel:SetVisible(true)
	panel:SetDraggable(true)
	panel:ShowCloseButton(true)
	panel:MakePopup()
	
	local labelName = vgui.Create("DLabel")
	labelName:SetParent(panel)
	labelName:SetPos(10, 25)
	labelName:SetSize(50, 25)
	labelName:SetText("Name:")
	
	local textfieldName = vgui.Create("DTextEntry")
	textfieldName:SetParent(panel)
	textfieldName:SetPos(75, 25)
	textfieldName:SetSize(100, 25)
	textfieldName:SetText("DuplicationName")
	
	local labelPrice = vgui.Create("DLabel")       
	labelPrice:SetParent(panel)
	labelPrice:SetPos(10, 75)
	labelPrice:SetSize(50, 25)
	labelPrice:SetText("Price: ")
	
	local textfieldPrice = vgui.Create("DTextEntry")
	textfieldPrice:SetParent(panel)
	textfieldPrice:SetPos(75, 75)
	textfieldPrice:SetSize(100, 25)
	textfieldPrice:SetText("100")
	
	local buttonSave = vgui.Create("DButton")
	buttonSave:SetParent(panel)
	buttonSave:SetText("Save")
	buttonSave:SetSize(100, 25)
	buttonSave:SetPos(50, 250)
	buttonSave.DoClick = function() 
		local price = tonumber(textfieldPrice:GetValue(), 10)
		local name = textfieldName:GetValue()
		
		if price and name then
			log("Saved duplication with ID: " .. dupeID, 1)
			panel:SetVisible(false)
			RunConsoleCommand("saveDuplication", name, price, dupeID)
		else
			createWarning("Please enter a valid name and price!")
		end
		
		 
	end
end

concommand.Add("logLevel", setLogLevel)
concommand.Add("openSaveGUI", createSaveFrame)
concommand.Add("createLoadFrame", createLoadFrame)
concommand.Add("addLoadFrameEntry", addLoadFrameEntry)