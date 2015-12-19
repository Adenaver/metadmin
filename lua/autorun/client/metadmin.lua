metadmin = metadmin or {}
metadmin.category = "MetAdmin" -- Категория в ulx
net.Receive("metadmin.settings", function()
	local tab = net.ReadTable()
	for k,v in pairs(tab) do
		metadmin[k] = v
	end
end)
net.Receive("metadmin.profile", function()
	metadmin.profile(net.ReadTable())
end)
net.Receive("metadmin.questions", function()
	metadmin.question(net.ReadTable())
end)
net.Receive("metadmin.viewanswers", function()
	metadmin.viewanswers(net.ReadTable())
end)
metadmin.questions = metadmin.questions or {}
net.Receive("metadmin.questionstab", function()
	metadmin.questions = net.ReadTable()
end)
net.Receive("metadmin.notify", function()
  chat.AddText(unpack(net.ReadTable()))
end)
CreateClientConVar("metadmin_preview",1,true,false)
local buttonmenu = CreateClientConVar("metadmin_buttonmenu","F4",true,false)

local function Access(permis)
	return ULib.ucl.query(LocalPlayer(),permis)
end

function metadmin.menu()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,260)
	Frame:SetTitle("Меню")
	Frame:SetDraggable( true )
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	if Access("ma.questionsmenu") then
		local questlist = vgui.Create("DButton",Frame)
		questlist:SetPos(630,2.5)
		questlist:SetText("Вопросы")
		questlist:SetSize(60,20)
		questlist.DoClick = function() metadmin.questionslist() Frame:Close() end
	end
	local settings = vgui.Create("DButton",Frame)
	settings:SetPos(690,2.5)
	settings:SetText("Настройки")
	settings:SetSize(70,20)
	settings.DoClick = function() metadmin.settings() Frame:Close() end
	local playerslist = vgui.Create("DListView",Frame)
	playerslist:SetPos(10,30)
	playerslist:SetSize(780,220)
	playerslist:SetMultiSelect(false)
	local menu
	playerslist.OnClickLine = function(panel,line)
		if IsValid(menu) then menu:Remove() end
		line:SetSelected(true)
		menu = DermaMenu()
		local header = menu:AddOption(line:GetValue(1))
		header:SetTextInset(10,0)
		header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
		local row = menu:AddOption("Профиль", function()
			RunConsoleCommand("ulx","prid",line:GetValue(3))
			Frame:Close()
		end)
		row:SetIcon("icon16/information.png")
		
		local sub, row = menu:AddSubMenu("Приказы")
		row:SetIcon("icon16/application_error.png")
			local sub2, row = sub:AddSubMenu("Пломбы")
			row:SetTextInset(10,0)
				for k,v in pairs(metadmin.plombs) do
					local row = sub2:AddOption(v, function()
						net.Start("metadmin.order")
							net.WriteEntity(line.ply)
							net.WriteString(k)
						net.SendToServer()
						Frame:Close()
					end)
					row:SetTextInset(10,0)
				end
				
		if Access("ma.starttest") then
			local sub, row = menu:AddSubMenu("Начать тест")
			for k,v in pairs(metadmin.questions) do
				if v.enabled == 1 then
					local row = sub:AddOption(v.name, function()
						if GetConVarNumber( "metadmin_preview" ) == 1 then
							metadmin.questions2(k,"view",{nick = line:GetValue(1),sid = line:GetValue(3)})
						else
							net.Start("metadmin.action")
								net.WriteString(sid)
								net.WriteInt(3,5)
								net.WriteString(k)
							net.SendToServer()
						end
						Frame:Close()
					end)
					row:SetTextInset(10,0)
				end
			end
			row:SetIcon("icon16/help.png")
		end
			
		local row = menu:AddOption("Отмена")
		row:SetIcon("icon16/cancel.png")
		
		menu.Remove = function(m)
			if IsValid(line) then
				line:SetSelected(false)
			end
		end
		menu:Open()
	end
	playerslist:AddColumn("Ник"):SetFixedWidth(400)
	playerslist:AddColumn("Группа"):SetFixedWidth(180)
	playerslist:AddColumn("SteamID"):SetFixedWidth(200)
	for k,v in pairs(player.GetAll()) do
		local line = playerslist:AddLine(v:Nick(),metadmin.ranks[v:GetUserGroup()],v:SteamID())
		line.ply = v
	end
end

local buttons = {["F2"] = KEY_F2,["F3"] = KEY_F3,["F4"] = KEY_F4}
function metadmin.settings()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(220,85)
	Frame:SetTitle("Настройки")
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	local serversettings = vgui.Create("DButton",Frame)
	serversettings:SetPos(70,2.5)
	serversettings:SetText("Настройки сервера")
	serversettings:SetSize(110,20)
	serversettings.DoClick = function() metadmin.serversettings() Frame:Close() end
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(210,50)
	DLabel:SetDark(1)
	local preview = vgui.Create("DCheckBoxLabel",Frame)
	preview:SetPos(10,35)
	preview:SetText("Предпросмотр (Начать тест)")
	preview:SetConVar("metadmin_preview")
	preview:SizeToContents()
	local buttontext = vgui.Create('DLabel',Frame)
	buttontext:SetPos(10,60)
	buttontext:SetText("Кнопка, открывающая меню:")
	buttontext:SizeToContents()
	local button = vgui.Create( "DComboBox",Frame )
	button:SetPos(165,55)
	button:SetSize(40,20)
	button:SetValue(buttonmenu:GetString())
	for k,v in pairs(buttons) do
		button:AddChoice(k)
	end
	button.OnSelect = function(panel,index,value)
		RunConsoleCommand("metadmin_buttonmenu",value)
	end
end

function metadmin.serversettings()
	if not Access("ma.settings") then return end
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(250,200)
	Frame:SetTitle("Настройки сервера")
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(240,165)
	DLabel:SetDark(1)
	
	local synch = vgui.Create("DCheckBoxLabel",Frame)
	synch:SetPos(10,35)
	synch:SetText("Синхронизация")
	synch:SetDisabled(true)
	synch.Button.DoClick = function(self)
	end
	synch:SizeToContents()
	
	local badpl = vgui.Create("DCheckBoxLabel",Frame)
	badpl:SetPos(135,35)
	badpl:SetText("'Плохие' игроки")
	badpl:SetDisabled(true)
	badpl.Button.DoClick = function(self)
	end
	badpl:SizeToContents()
	
	local groupwrite = vgui.Create("DCheckBoxLabel",Frame)
	groupwrite:SetPos(135,60)
	groupwrite:SetText("Перезапись")
	groupwrite:SetChecked(metadmin.groupwrite)
	groupwrite:SetToolTip("Записывает группу при первом входе/Устанавливает user при первом входе")
	groupwrite.OnChange = function(self, value)
		net.Start("metadmin.settings")
			net.WriteTable({groupwrite=value})
		net.SendToServer()
	end
	groupwrite:SizeToContents()
	
	local showserver = vgui.Create("DCheckBoxLabel",Frame)
	showserver:SetPos(10,60)
	showserver:SetText("Показ. сервер")
	showserver:SetChecked(metadmin.showserver)
	showserver:SetToolTip("Показывает имя сервера в нарушениях/экзаменах")
	showserver.OnChange = function(self, value)
		net.Start("metadmin.settings")
			net.WriteTable({showserver=value})
		net.SendToServer()
	end
	showserver:SizeToContents()
	
	local voice = vgui.Create("DCheckBoxLabel",Frame)
	voice:SetPos(10,85)
	voice:SetText("Голосовой чат")
	voice:SetChecked(metadmin.showserver)
	voice:SetToolTip("Диспетчер слышит всех, остальные слышат только диспетчера")
	voice.OnChange = function(self, value)
		net.Start("metadmin.settings")
			net.WriteTable({voice=value})
		net.SendToServer()
	end
	voice:SizeToContents()
	
	local server = vgui.Create("DButton",Frame)
	server:SetPos(10,115)
	server:SetSize(105,20)
	server:SetText("Имя сервера")
	server.DoClick = function()
		local frame = vgui.Create("DFrame")
		frame:SetSize(150,75)
		frame:SetTitle("Название сервера")
		frame:SetDraggable(true)
		frame:Center()
		frame:MakePopup()
		frame.btnMaxim:SetVisible(false)
		frame.btnMinim:SetVisible(false)
		local text = vgui.Create("DTextEntry",frame)
		text:SetPos(5,30)
		text:SetSize(140,20)
		text:SetText(metadmin.server)
		local send = vgui.Create("DButton",frame)
		send:SetPos(5,50)
		send:SetText("Сохранить")
		send:SetSize(140,20)
		send.DoClick = function()
			net.Start("metadmin.settings")
				net.WriteTable({server= text:GetValue()})
			net.SendToServer()
			frame:Close()
		end
	end
	
	local disp = vgui.Create("DComboBox",Frame)
	disp:SetPos(135,115)
	disp:SetSize(105,20)
	disp:SetToolTip("Группа диспетчера")
	disp:SetText(metadmin.ranks[metadmin.disp] or metadmin.disp)
	for k,v in pairs(metadmin.ranks) do
		disp:AddChoice(v)
	end
	disp.OnSelect = function(self,index,value)
		net.Start("metadmin.settings")
			net.WriteTable({disp=table.KeyFromValue(metadmin.ranks,value)})
		net.SendToServer()
	end
	
	local ranks = vgui.Create("DButton",Frame)
	ranks:SetPos(10,145)
	ranks:SetText("Ранги")
	ranks:SetSize(70,20)
	ranks.DoClick = function()
		Frame:Close()
		local Frame = vgui.Create( "DFrame" )
		Frame:SetSize(500,260)
		Frame:SetTitle("Ранги")
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible(false)
		Frame.btnMinim:SetVisible(false)
		Frame:MakePopup()
		Frame:Center()
		
		local list = vgui.Create("DListView",Frame)
		list:SetPos(10,30)
		list:SetSize(480,220)
		list:SetMultiSelect(false)
		local save = vgui.Create("DButton",Frame)
		save:SetPos(390,2.5)
		save:SetText("Сохранить")
		save:SetSize(70,20)
		save.DoClick = function()
			local tab = {}
			tab.ranks = {}
			for k,v in pairs(list.Lines) do
				tab.ranks[v:GetValue(1)] = v:GetValue(2)
			end
			net.Start("metadmin.settings")
				net.WriteTable(tab)
			net.SendToServer()
			Frame:Close()
		end
		
		list:AddColumn("ID")
		list:AddColumn("Name")
		
		local add = vgui.Create("DButton",Frame)
		add:SetPos(330,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() list:AddLine("новый","ранг") end
		for k,v in pairs(metadmin.ranks) do
			list:AddLine(k,v)
		end
		local menu
		list.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Изменить", function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(200,100)
				Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
				Frame2:SetDraggable(true)
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				Frame2:MakePopup()
				Frame2:Center()
				local text1 = vgui.Create("DTextEntry",Frame2)
				text1:SetPos(5,30)
				text1:SetText(line:GetValue(1))
				text1:SetSize(190,20)
				local text2 = vgui.Create("DTextEntry",Frame2)
				text2:SetPos(5,50)
				text2:SetText(line:GetValue(2))
				text2:SetSize(190,20)
				local edit = vgui.Create("DButton", Frame2)
				edit:SetPos(5,75)
				edit:SetText("Изменить")
				edit:SetSize(190,20)
				edit.DoClick = function()
					line:SetValue(1,text1:GetValue())
					line:SetValue(2,text2:GetValue())
					Frame2:Close()
				end
			end)
			row:SetIcon("icon16/pencil.png")
		
			local row = menu:AddOption("Удалить", function()
				panel:RemoveLine(line:GetID())
			end)
			row:SetIcon("icon16/delete.png")
		
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	end
	
	local prom = vgui.Create("DButton",Frame)
	prom:SetPos(90,145)
	prom:SetText("Повышения")
	prom:SetSize(70,20)
	prom.DoClick = function()
		Frame:Close()
		local Frame = vgui.Create( "DFrame" )
		Frame:SetSize(500,260)
		Frame:SetTitle("Повышения")
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible(false)
		Frame.btnMinim:SetVisible(false)
		Frame:MakePopup()
		Frame:Center()
		
		local list = vgui.Create("DListView",Frame)
		list:SetPos(10,30)
		list:SetSize(480,220)
		list:SetMultiSelect(false)
		local save = vgui.Create("DButton",Frame)
		save:SetPos(390,2.5)
		save:SetText("Сохранить")
		save:SetSize(70,20)
		save.DoClick = function()
			local tab = {}
			tab.prom = {}
			for k,v in pairs(list.Lines) do
				tab.prom[v:GetValue(1)] = v:GetValue(2)
			end
			net.Start("metadmin.settings")
				net.WriteTable(tab)
			net.SendToServer()
			Frame:Close()
		end
		
		list:AddColumn("Предыдущий ранг")
		list:AddColumn("Следующий ранг")
		
		local add = vgui.Create("DButton",Frame)
		add:SetPos(330,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() list:AddLine("новый","ранг") end
		for k,v in pairs(metadmin.prom) do
			list:AddLine(k,v)
		end
		local menu
		list.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Изменить", function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(200,100)
				Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
				Frame2:SetDraggable(true)
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				Frame2:MakePopup()
				Frame2:Center()
				local text1 = vgui.Create("DTextEntry",Frame2)
				text1:SetPos(5,30)
				text1:SetText(line:GetValue(1))
				text1:SetSize(190,20)
				local text2 = vgui.Create("DTextEntry",Frame2)
				text2:SetPos(5,50)
				text2:SetText(line:GetValue(2))
				text2:SetSize(190,20)
				local edit = vgui.Create("DButton", Frame2)
				edit:SetPos(5,75)
				edit:SetText("Изменить")
				edit:SetSize(190,20)
				edit.DoClick = function()
					line:SetValue(1,text1:GetValue())
					line:SetValue(2,text2:GetValue())
					Frame2:Close()
				end
			end)
			row:SetIcon("icon16/pencil.png")
		
			local row = menu:AddOption("Удалить", function()
				panel:RemoveLine(line:GetID())
			end)
			row:SetIcon("icon16/delete.png")
		
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	end
	
	local dem = vgui.Create("DButton",Frame)
	dem:SetPos(170,145)
	dem:SetText("Понижения")
	dem:SetSize(70,20)
	dem.DoClick = function()
		Frame:Close()
		local Frame = vgui.Create( "DFrame" )
		Frame:SetSize(500,260)
		Frame:SetTitle("Понижения")
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible(false)
		Frame.btnMinim:SetVisible(false)
		Frame:MakePopup()
		Frame:Center()
		
		local list = vgui.Create("DListView",Frame)
		list:SetPos(10,30)
		list:SetSize(480,220)
		list:SetMultiSelect(false)
		local save = vgui.Create("DButton",Frame)
		save:SetPos(390,2.5)
		save:SetText("Сохранить")
		save:SetSize(70,20)
		save.DoClick = function()
			local tab = {}
			tab.dem = {}
			for k,v in pairs(list.Lines) do
				tab.dem[v:GetValue(1)] = v:GetValue(2)
			end
			net.Start("metadmin.settings")
				net.WriteTable(tab)
			net.SendToServer()
			Frame:Close()
		end
		
		list:AddColumn("Предыдущий ранг")
		list:AddColumn("Следующий ранг")
		
		local add = vgui.Create("DButton",Frame)
		add:SetPos(330,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() list:AddLine("новый","ранг") end
		for k,v in pairs(metadmin.dem) do
			list:AddLine(k,v)
		end
		local menu
		list.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Изменить", function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(200,100)
				Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
				Frame2:SetDraggable(true)
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				Frame2:MakePopup()
				Frame2:Center()
				local text1 = vgui.Create("DTextEntry",Frame2)
				text1:SetPos(5,30)
				text1:SetText(line:GetValue(1))
				text1:SetSize(190,20)
				local text2 = vgui.Create("DTextEntry",Frame2)
				text2:SetPos(5,50)
				text2:SetText(line:GetValue(2))
				text2:SetSize(190,20)
				local edit = vgui.Create("DButton", Frame2)
				edit:SetPos(5,75)
				edit:SetText("Изменить")
				edit:SetSize(190,20)
				edit.DoClick = function()
					line:SetValue(1,text1:GetValue())
					line:SetValue(2,text2:GetValue())
					Frame2:Close()
				end
			end)
			row:SetIcon("icon16/pencil.png")
		
			local row = menu:AddOption("Удалить", function()
				panel:RemoveLine(line:GetID())
			end)
			row:SetIcon("icon16/delete.png")
		
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	end
	
	local plombs = vgui.Create("DButton",Frame)
	plombs:SetPos(10,170)
	plombs:SetText("Пломбы")
	plombs:SetSize(110,20)
	plombs.DoClick = function()
		Frame:Close()
		local Frame = vgui.Create( "DFrame" )
		Frame:SetSize(500,260)
		Frame:SetTitle("Пломбы")
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible(false)
		Frame.btnMinim:SetVisible(false)
		Frame:MakePopup()
		Frame:Center()
		
		local list = vgui.Create("DListView",Frame)
		list:SetPos(10,30)
		list:SetSize(480,220)
		list:SetMultiSelect(false)
		local save = vgui.Create("DButton",Frame)
		save:SetPos(390,2.5)
		save:SetText("Сохранить")
		save:SetSize(70,20)
		save.DoClick = function()
			local tab = {}
			tab.plombs = {}
			for k,v in pairs(list.Lines) do
				tab.plombs[v:GetValue(1)] = v:GetValue(2)
			end
			net.Start("metadmin.settings")
				net.WriteTable(tab)
			net.SendToServer()
			Frame:Close()
		end
		
		list:AddColumn("Англ.")
		list:AddColumn("Рус.")
		
		local add = vgui.Create("DButton",Frame)
		add:SetPos(330,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() list:AddLine("новая","пломба") end
		for k,v in pairs(metadmin.plombs) do
			list:AddLine(k,v)
		end
		local menu
		list.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Изменить", function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(200,100)
				Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
				Frame2:SetDraggable(true)
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				Frame2:MakePopup()
				Frame2:Center()
				local text1 = vgui.Create("DTextEntry",Frame2)
				text1:SetPos(5,30)
				text1:SetText(line:GetValue(1))
				text1:SetSize(190,20)
				local text2 = vgui.Create("DTextEntry",Frame2)
				text2:SetPos(5,50)
				text2:SetText(line:GetValue(2))
				text2:SetSize(190,20)
				local edit = vgui.Create("DButton", Frame2)
				edit:SetPos(5,75)
				edit:SetText("Изменить")
				edit:SetSize(190,20)
				edit.DoClick = function()
					line:SetValue(1,text1:GetValue())
					line:SetValue(2,text2:GetValue())
					Frame2:Close()
				end
			end)
			row:SetIcon("icon16/pencil.png")
		
			local row = menu:AddOption("Удалить", function()
				panel:RemoveLine(line:GetID())
			end)
			row:SetIcon("icon16/delete.png")
		
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	end
	local pogona = vgui.Create("DButton",Frame)
	pogona:SetPos(130,170)
	pogona:SetText("Погоны")
	pogona:SetSize(110,20)
	pogona.DoClick = function()
		Frame:Close()
		local Frame = vgui.Create( "DFrame" )
		Frame:SetSize(500,260)
		Frame:SetTitle("Погоны")
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible(false)
		Frame.btnMinim:SetVisible(false)
		Frame:MakePopup()
		Frame:Center()
		
		local list = vgui.Create("DListView",Frame)
		list:SetPos(10,30)
		list:SetSize(480,220)
		list:SetMultiSelect(false)
		local save = vgui.Create("DButton",Frame)
		save:SetPos(390,2.5)
		save:SetText("Сохранить")
		save:SetSize(70,20)
		save.DoClick = function()
			local tab = {}
			tab.pogona = {}
			for k,v in pairs(list.Lines) do
				tab.pogona[v:GetValue(1)] = v:GetValue(2)
			end
			net.Start("metadmin.settings")
				net.WriteTable(tab)
			net.SendToServer()
			Frame:Close()
		end
		
		list:AddColumn("Группа")
		list:AddColumn("Путь")
		
		local add = vgui.Create("DButton",Frame)
		add:SetPos(330,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() list:AddLine("новая","погона") end
		for k,v in pairs(metadmin.pogona) do
			list:AddLine(k,v)
		end
		local menu
		list.OnClickLine = function(panel,line)
			if IsValid(menu) then menu:Remove() end
			line:SetSelected(true)
			menu = DermaMenu()
			local header = menu:AddOption(line:GetValue(1).." - "..line:GetValue(2))
			header:SetTextInset(10,0)
			header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
			local row = menu:AddOption("Изменить", function()
				local Frame2 = vgui.Create("DFrame")
				Frame2:SetSize(200,100)
				Frame2:SetTitle(line:GetValue(1).." - "..line:GetValue(2))
				Frame2:SetDraggable(true)
				Frame2.btnMaxim:SetVisible(false)
				Frame2.btnMinim:SetVisible(false)
				Frame2:MakePopup()
				Frame2:Center()
				local text1 = vgui.Create("DTextEntry",Frame2)
				text1:SetPos(5,30)
				text1:SetText(line:GetValue(1))
				text1:SetSize(190,20)
				local text2 = vgui.Create("DTextEntry",Frame2)
				text2:SetPos(5,50)
				text2:SetText(line:GetValue(2))
				text2:SetSize(190,20)
				local edit = vgui.Create("DButton", Frame2)
				edit:SetPos(5,75)
				edit:SetText("Изменить")
				edit:SetSize(190,20)
				edit.DoClick = function()
					line:SetValue(1,text1:GetValue())
					line:SetValue(2,text2:GetValue())
					Frame2:Close()
				end
			end)
			row:SetIcon("icon16/pencil.png")
		
			local row = menu:AddOption("Удалить", function()
				panel:RemoveLine(line:GetID())
			end)
			row:SetIcon("icon16/delete.png")
		
			local row = menu:AddOption("Отмена")
			row:SetIcon("icon16/cancel.png")
		
			menu.Remove = function(m)
				if IsValid(line) then
					line:SetSelected(false)
				end
			end
			menu:Open()
		end
	end
end

local opentime = 0
hook.Add("Think","exammenu",function()
	if not Access("ma.pl") then return end
	if CurTime() < opentime then return end
    if input.IsKeyDown(buttons[buttonmenu:GetString()]) then
      metadmin.menu()
	  opentime = CurTime() + 2.5
	end
end)

local menu
function metadmin.playeract(nick,sid,rank,Frame)
	if IsValid(menu) then menu:Remove() end
	menu = DermaMenu()
	local header = menu:AddOption(nick)
	header:SetTextInset(10,0)
	header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
	if Access("ma.violationgive") then
		local row = menu:AddOption("Добавить нарушение", function()
			local frame = vgui.Create("DFrame")
			frame:SetSize(585,140)
			frame:SetTitle("Добавление нарушения")
			frame:SetDraggable(true)
			frame:Center()
			frame:MakePopup()
			frame.btnMaxim:SetVisible(false)
			frame.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame)
			text:SetPos(5,25)
			text:SetSize(575,85)
			text:SetMultiline(true)
			text:SetText("Нарушение")
			local send = vgui.Create("DButton",frame)
			send:SetPos(5,115)
			send:SetText("Отправить")
			send:SetSize(575,20)
			send.DoClick = function()
				net.Start("metadmin.violations")
					net.WriteInt(1,3)
					net.WriteString(sid)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame:Close()
				RunConsoleCommand("ulx","prid",sid)
			end
			Frame:Close()
		end)
		row:SetIcon("icon16/information.png")
	end
	if Access("ma.settalon") then
		row = menu:AddOption("Вернуть талон", function()
			net.Start("metadmin.action")
				net.WriteString(sid)
				net.WriteInt(7,5)
			net.SendToServer()
			Frame:Close()
			RunConsoleCommand("ulx","prid",sid)
		end)
		row:SetIcon("icon16/tag_blue_add.png")
		row = menu:AddOption("Забрать талон", function()
			net.Start("metadmin.action")
				net.WriteString(sid)
				net.WriteInt(8,5)
			net.SendToServer()
			Frame:Close()
			RunConsoleCommand("ulx","prid",sid)
		end)
		row:SetIcon("icon16/tag_blue_delete.png")
	end
	if Access("ma.promote") and metadmin.prom[rank] then
		row = menu:AddOption("Повысить", function()
			local frame2 = vgui.Create("DFrame")
			frame2:SetSize(400, 60)
			frame2:SetTitle("Примечание")
			frame2:Center()
			frame2.btnMaxim:SetVisible(false)
			frame2.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame2)
			text:StretchToParent(5,29,5,5)
			text.OnEnter = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(1,5)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame2:Close()
				RunConsoleCommand("ulx","prid",sid)
			end
			text:RequestFocus()
			frame2:MakePopup()
			Frame:Close()
		end)
		row:SetIcon("icon16/arrow_up.png")
	end
	if Access("ma.demote") and metadmin.dem[rank] then
		row = menu:AddOption("Понизить", function()
			local frame2 = vgui.Create("DFrame")
			frame2:SetSize(400,60)
			frame2:SetTitle("Примечание")
			frame2:Center()
			frame2.btnMaxim:SetVisible(false)
			frame2.btnMinim:SetVisible(false)
			local text = vgui.Create("DTextEntry",frame2)
			text:StretchToParent(5,29,5,5)
			text.OnEnter = function()
				net.Start("metadmin.action")
					net.WriteString(sid)
					net.WriteInt(2,5)
					net.WriteString(text:GetValue())
				net.SendToServer()
				frame2:Close()
				RunConsoleCommand("ulx","prid",sid)
			end
			text:RequestFocus()
			frame2:MakePopup()
			Frame:Close()
		end)
		row:SetIcon("icon16/arrow_down.png")
	end
	if Access("ulx setrankid") then
		local sub, row = menu:AddSubMenu("Установить ранг")
		row:SetIcon("icon16/lightning_go.png")
		row:SetTextInset(10,0)
		for k,v in pairs(metadmin.ranks) do
			local row = sub:AddOption(v, function()
				RunConsoleCommand("ulx","setrankid",sid,k)
				Frame:Close()
			end)
			row:SetTextInset(10,0)
		end
	end
	local target = player.GetBySteamID(sid)
	if target then
		if Access("ma.starttest") then
			local sub, row = menu:AddSubMenu("Начать тест")
			for k,v in pairs(metadmin.questions) do
				if v.enabled == 1 then
					local row = sub:AddOption(v.name, function()
						if GetConVarNumber( "metadmin_preview" ) == 1 then
							metadmin.questions2(k,"view",{nick = nick,sid = sid})
						else
							net.Start("metadmin.action")
								net.WriteString(sid)
								net.WriteInt(3,5)
								net.WriteString(k)
							net.SendToServer()
						end
						Frame:Close()
					end)
					row:SetTextInset(10,0)
				end
			end
			row:SetIcon("icon16/help.png")
		end
	end
	local row = menu:AddOption("Отмена")
	row:SetIcon("icon16/cancel.png")
	menu.Remove = function(m)
		DMenu.Remove(m)
	end
	menu:Open()
end

surface.CreateFont("ma.font1", {
	font = "Trebuchet",
	size = 17,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})
	
surface.CreateFont("ma.font2", {
	font = "Trebuchet",
	size = 30,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font3", {
	font = "Trebuchet",
	size = 24,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font4", {
	font = "Trebuchet",
	size = 20,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = true,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})

surface.CreateFont("ma.font5", {
	font = "Trebuchet",
	size = 20,
	weight = 800,
	blursize = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
})
	
local badplok = {}
function metadmin.profile(tab)
	if tab.badpl and not badplok[tab.SID] then
		local frame = Derma_Message("Этот игрок был отмечен 'плохим' в системе.\nПричина: "..tab.badpl,"Предупреждение","Ок")
		local hided = vgui.Create("DCheckBoxLabel",frame)
		hided:SetSize(100,20)
		hided:SetPos(165,5)
		hided:SetText("Не показывать")
		hided:SetValue(badplok[tab.SID] or 0)
		function hided:OnChange(val)
			badplok[tab.SID] = val
		end
	end
	local creatabs = (tab.violations or tab.exam or tab.exam_answers or tab.status)
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(600,creatabs and 500 or 115)
	Frame:SetTitle("Профиль "..tab.Nick.." ("..tab.SID..")")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DPanel = vgui.Create("DPanel",Frame)
	DPanel:SetPos(5,30)
	DPanel:SetSize(590,80)
	DLabel:SetDark(1)
	if tab.synch then
		local synch = vgui.Create("DImage",Frame)
		if Access("ma.pl") then
			synch:SetPos(484,3)
		else
			synch:SetPos(544,3)
		end
		synch:SetSize(16,16)
		local synched = tab.synch.rank == tab.rank
		synch:SetImage(synched and "icon16/tick.png" or "icon16/cross.png")
		synch:SetToolTip(synched and "Синхронизирован" or "Не синхронизирован")
		synch:SetMouseInputEnabled(true)
		local com = tab.synch.com and ("\nКомментарий: "..tab.synch.com) or ""
		function synch:OnCursorEntered()
			self:SetCursor("hand")
		end
		function synch:OnCursorExited()
			self:SetCursor("arrow")
		end
		function synch:OnMouseReleased(code)
			if (code == MOUSE_LEFT) then
				if not synched then
					if Access("ulx setrank") then
						if metadmin.ranks[tab.synch.rank] then
							Derma_Query("Текущий ранг: "..tab.rank.."\nРеком. ранг: "..tab.synch.rank..com.."\nСинхронизировать?", "Синхронизация",
								"Да", function() RunConsoleCommand("ulx","setrankid",tab.SID,tab.synch.rank) Frame:Close() end,
								"Нет")
						else
							Derma_Query("Текущий ранг: "..tab.rank.."\nРекомендованный ранг: "..tab.synch.rank..com.."\nСинхронизация невозможна, данный ранг отсутствует в системе.", "Синхронизация","Закрыть")
						end
					else
						Derma_Query("Текущий ранг: "..tab.rank.."\nРекомендованный ранг: "..tab.synch.rank..com, "Синхронизация","Закрыть")
					end
				else
					Derma_Query("Ранг: "..tab.synch.rank..com,"Синхронизация","Закрыть")
				end
			end
		end
	end
	if Access("ma.pl") then
		local DButton = vgui.Create("DButton",Frame)
		DButton:SetPos(504,3)
		DButton:SetText("Действия")
		DButton:SetSize(60,18)
		DButton.DoClick = function()
			metadmin.playeract(tab.Nick,tab.SID,tab.rank,Frame)
		end
	end
	local nick = vgui.Create("DLabel",DPanel)
	nick:SetPos(75,5)
	nick:SetText("Ник: "..tab.Nick)
	nick:SizeToContents()
	
	local steamid = vgui.Create("DLabel",DPanel)
	steamid:SetPos(75,20)
	steamid:SetText("STEAMID:")
	steamid:SizeToContents()
	
	local steamid2 = vgui.Create("DLabel",DPanel)
	steamid2:SetPos(125,20)
	steamid2:SetText(tab.SID)
	steamid2:SetTextColor(Color(0, 0, 255))
	steamid2:SetToolTip("Копировать")
	steamid2:SizeToContents()
	steamid2:SetMouseInputEnabled(true)
	
	function steamid2:OnCursorEntered()
		self:SetCursor("hand")
	end
	function steamid2:OnCursorExited()
		self:SetCursor("arrow")
	end
	function steamid2:OnMousePressed(code)
		if (code == MOUSE_LEFT) then
			self.wasPressed = CurTime()
		end
	end
	function steamid2:OnMouseReleased()
		if (self.wasPressed and CurTime()-self.wasPressed <= 0.16) then
			SetClipboardText(tab.SID)
		end
		self.wasPressed = nil
	end
	
	local rank = vgui.Create("DLabel",DPanel)
	rank:SetPos(75,35)
	rank:SetText("Ранг: "..metadmin.ranks[tab.rank])
	rank:SizeToContents()
	local nvoiol = vgui.Create("DLabel",DPanel)
	nvoiol:SetPos(75,50)
	nvoiol:SetText("Нарушений: "..tab.nvio)
	nvoiol:SizeToContents()
	local Avatar = vgui.Create("AvatarImage",DPanel)
	Avatar:SetSize(64,64)
	Avatar:SetPos(5,7)
	Avatar:SetSteamID(util.SteamIDTo64(tab.SID),64)
	function Avatar:OnCursorEntered()
		self:SetCursor("hand")
	end
	function Avatar:OnCursorExited()
		self:SetCursor("arrow")
	end
	function Avatar:OnMouseReleased(code)
		if (code == MOUSE_LEFT) then
			gui.OpenURL("http://steamcommunity.com/profiles/"..util.SteamIDTo64(tab.SID))
		end
	end
	if metadmin.pogona[tab.rank] then
		local pogona = vgui.Create("DImage",DPanel)
		pogona:SetImage(metadmin.pogona[tab.rank])
		pogona:SetSize(140,78)
		pogona:SetPos(450,1)
	end
	
	if not creatabs then return end
	local tabs = vgui.Create("DPropertySheet",Frame)
	tabs:SetPos(0,110)
	tabs:SetSize(600,390)
	if tab.violations then
		local violations = vgui.Create("DPanel",tabs)
		violations:SetBackgroundColor(Color(128,128,128))
		violations.PaintOver = function(self,w,h)
			if tab.nvio == 0 then
				draw.SimpleText("Этот игрок еще ничего не нарушил.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
				draw.SimpleText("Пока...", "ma.font1", w/2, 60, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",violations)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.violations) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,80*num)
			DPanel:SetSize(584,75)
			DLabel:SetDark(1)
			if Access("ma.violationremove") then
				local menu
				function DPanel:OnMouseReleased()
					if IsValid(menu) then menu:Remove() end
					menu = DermaMenu()
					local header = menu:AddOption("№"..k)
					header:SetTextInset(10,0)
					header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
					local row = menu:AddOption("Удалить", function()
						net.Start("metadmin.violations")
							net.WriteInt(2,3)
							net.WriteString(tab.SID)
							net.WriteString(v.id)
						net.SendToServer()
						Frame:Close()
						RunConsoleCommand("ulx","prid",tab.SID)
					end)
					row:SetIcon("icon16/table_delete.png")
					local row = menu:AddOption("Отмена")
					row:SetIcon("icon16/cancel.png")
					menu:Open()
				end
			end
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(5,5)
			info:SetText("№"..k.." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date).." | Выдал: "..v.admin..(metadmin.showserver and " | Сервер: "..v.server or ""))
			local reason = vgui.Create("DTextEntry",DPanel)
			reason:SetPos(5,25)
			reason:SetSize(574,45)
			reason:SetText(v.violation)
			reason:SetMultiline(true)
			reason:SetEditable(false)
			num = num + 1
		end
		tabs:AddSheet("Нарушения",violations,"icon16/exclamation.png")
	end
	if tab.exam then
		local examinfo = vgui.Create("DPanel",tabs)
		examinfo:SetBackgroundColor(Color(128,128,128))
		examinfo.PaintOver = function(self,w,h)
			if #tab.exam == 0 then
				draw.SimpleText("Этот игрок пока не сдал ни одного экзамена.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",examinfo)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.exam) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,65*num)
			DPanel:SetSize(584,60)
			DLabel:SetDark(1)
			DPanel:SetBackgroundColor(v.type == 1 and Color(46,139,87) or v.type == 2 and Color(250,128,114) or Color(255,255,150))
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(5,5)
			info:SetText((metadmin.ranks[v.rank] or v.rank).." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date).." | Экзаменатор: "..v.examiner..(metadmin.showserver and " | Сервер: "..v.server or ""))
			local note = vgui.Create("DTextEntry",DPanel)
			note:SetPos(5,25)
			note:SetSize(574,30)
			note:SetText(v.note)
			note:SetMultiline(true)
			note:SetEditable(false)
			num = num + 1
		end
		tabs:AddSheet("Результаты экзаменов",examinfo,"icon16/layout_edit.png")
	end
	if tab.exam_answers then
		local answers = vgui.Create("DPanel",tabs)
		answers:SetBackgroundColor(Color(128,128,128))
		answers.PaintOver = function(self,w,h)
			if #tab.exam_answers == 0 then
				draw.SimpleText("Этот игрок пока не сдал ни одного теста.", "ma.font3", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			end
		end
		local DScrollPanel = vgui.Create("DScrollPanel",answers)
		DScrollPanel:SetSize(600,355)
		DScrollPanel:SetPos(0,0)
		local num = 0
		for k,v in pairs(tab.exam_answers) do
			local DPanel = vgui.Create("DPanel",DScrollPanel)
			DPanel:SetPos(0,30*num)
			DPanel:SetSize(584,25)
			DLabel:SetDark(1)
			if metadmin.questions[v.questions] and (Access("ma.viewresults") or Access("ma.setstattest")) then
				local menu
				function DPanel:OnMouseReleased()
					if IsValid(menu) then menu:Remove() end
					menu = DermaMenu()
					if Access("ma.viewresults") then
						local row = menu:AddOption("Просмотреть", function()
							net.Start("metadmin.action")
								net.WriteString(tab.SID)
								net.WriteInt(4,5)
								net.WriteString(v.id)
							net.SendToServer()
							Frame:Close()
						end)
						row:SetIcon("icon16/information.png")
					end
					if Access("ma.setstattest") then
						local sub, row = menu:AddSubMenu("Статус")
						row:SetIcon(v.status == 1 and "icon16/tick.png" or v.status == 2 and "icon16/cross.png" or "icon16/help.png")
						local row = sub:AddOption("Сдал", function()
							net.Start("metadmin.action")
								net.WriteString(tab.SID)
								net.WriteInt(5,5)
								net.WriteString(v.id)
								net.WriteInt(1,4)
							net.SendToServer()
							Frame:Close()
						end)
						row:SetIcon("icon16/tick.png")
						local row = sub:AddOption("Не сдал", function()
							net.Start("metadmin.action")
								net.WriteString(tab.SID)
								net.WriteInt(5,5)
								net.WriteString(v.id)
								net.WriteInt(2,4)
							net.SendToServer()
							Frame:Close()
						end)
						row:SetIcon("icon16/cross.png")
						local row = sub:AddOption("На проверке", function()
							net.Start("metadmin.action")
								net.WriteString(tab.SID)
								net.WriteInt(5,5)
								net.WriteString(v.id)
								net.WriteInt(0,4)
							net.SendToServer()
							Frame:Close()
						end)
						row:SetIcon("icon16/help.png")
					end
					local row = menu:AddOption("Отмена")
					row:SetIcon("icon16/cancel.png")
					menu:Open()
				end
			end
			local img = vgui.Create("DImage",DPanel)
			img:SetPos(5,5)
			img:SetSize(16,16)
			img:SetImage(v.status == 1 and "icon16/tick.png" or v.status == 2 and "icon16/cross.png" or "icon16/help.png")
			img:SetToolTip(v.status == 1 and "Сдал" or v.status == 2 and "Не сдал" or "На проверке")
			img:SetMouseInputEnabled(true)
			local info = vgui.Create("DLabel",DPanel)
			info:SetSize(574,15)
			info:SetPos(25,5)
			info:SetText("| "..v.name.." | Дата: "..os.date( "%X - %d/%m/%Y" ,v.date)..(v.admin != "" and " | Выдал: "..v.admin or "")..(v.ssadmin != "" and " | Проверил: "..v.ssadmin or ""))
			num = num + 1
		end
		tabs:AddSheet("Результаты тестов", answers,"icon16/page_edit.png")
	end
	if tab.status then
		local talon = vgui.Create("DPanel",tabs)
		talon:SetBackgroundColor(Color(255,228,181))
		talon.PaintOver = function(self,w,h)
			surface.SetDrawColor(tab.status.nom == 1 and Color(3,111,35) or tab.status.nom == 2 and Color(255,255,0) or Color(178,34,34))
			draw.NoTexture()
			surface.DrawPoly({{ x = 0, y = 0 },{ x = 40, y = 0 },{ x = w, y = h },{ x = w-40, y = h }})
			draw.SimpleText(GetHostName(), "ma.font1", w/2, 20, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("ТАЛОН ПРЕДУПРЕЖДЕНИЯ №"..tab.status.nom, "ma.font2", w/2, 55, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("Машиниста, помощника машиниста", "ma.font3", w/2, 90, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.Nick, "ma.font4", w/2, 120, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.SID, "ma.font4", w/2, 140, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText("Выдан: "..os.date( "%X - %d/%m/%Y" ,tab.status.date), "ma.font5", w/2, 180, Color(50,50,50), TEXT_ALIGN_CENTER)
			draw.SimpleText(tab.status.admin, "ma.font5", w/2, 200, Color(50,50,50), TEXT_ALIGN_CENTER)
		end
		tabs:AddSheet("Талон",talon,"icon16/vcard.png")
	end
end

function metadmin.questionslist()
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(200,260)
	Frame:SetTitle("Список шаблонов")
	Frame:SetDraggable(true)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:MakePopup()
	Frame:Center()
	if Access("ma.questionscreate") then
		local add = vgui.Create("DButton",Frame)
		add:SetPos(103,2.5)
		add:SetText("Добавить")
		add:SetSize(60,20)
		add.DoClick = function() metadmin.questionsadd() Frame:Close() end
	end
	local questionlist = vgui.Create("DListView",Frame)
	questionlist:SetPos(10,30)
	questionlist:SetSize(180,220)
	questionlist:SetMultiSelect(false)
	local menu
	questionlist.OnClickLine = function(panel,line)
		if IsValid(menu) then menu:Remove() end
		line:SetSelected(true)
		menu = DermaMenu()
		local header = menu:AddOption(line:GetValue(1))
		header:SetTextInset(10,0)
		header.PaintOver = function() surface.SetDrawColor(0,0,0,50) surface.DrawRect(0,0,header:GetWide(),header:GetTall()) end
		
		local row = menu:AddOption("Посмотреть вопросы", function()
			metadmin.questions2(line.id)
			Frame:Close()
		end)
		row:SetIcon("icon16/table.png")
		if Access("ma.questionsedit") then
			local sub, row = menu:AddSubMenu("Редактировать")
			row:SetIcon("icon16/table_edit.png")
				local row = sub:AddOption("Имя", function()
					local frame = vgui.Create("DFrame")
					frame:SetSize(150,75)
					frame:SetTitle("Название сервера")
					frame:SetDraggable(true)
					frame:Center()
					frame:MakePopup()
					frame.btnMaxim:SetVisible(false)
					frame.btnMinim:SetVisible(false)
					local text = vgui.Create("DTextEntry",frame)
					text:SetPos(5,30)
					text:SetSize(140,20)
					text:SetText(line:GetValue(1))
					local send = vgui.Create("DButton",frame)
					send:SetPos(5,50)
					send:SetText("Сохранить")
					send:SetSize(140,20)
					local id = line.id
					send.DoClick = function()
						net.Start("metadmin.qaction")
							net.WriteInt(5,5)
							net.WriteInt(id,32)
							net.WriteString(text:GetValue())
						net.SendToServer()
						frame:Close()
					end
					Frame:Close()
				end)
				row:SetTextInset(10,0)
				local row = sub:AddOption("Шаблон", function()
					metadmin.questions2(line.id,"edit")
					Frame:Close()
				end)
				row:SetTextInset(10,0)
		end
		if Access("ma.questionsimn") then
			local row = menu:AddOption(line.enabled==0 and"Включить"or"Отключить", function()
				net.Start("metadmin.qaction")
					net.WriteInt(1,5)
					net.WriteInt(line.id,32)
				net.SendToServer()
				Frame:Close()
				timer.Simple(0.25,function()
					metadmin.questionslist()
				end)
			end)
			row:SetIcon(line:GetValue(2)==0 and "icon16/table_row_insert.png"or"icon16/table_row_delete.png")
		end
		if Access("ma.questionsremove") then
			local name = line:GetValue(1)
			local row = menu:AddOption("Удалить", function()
				local id = line.id
				Derma_Query('Ты точно хочешь удалить ' .. name .. '?', 'Удаление шаблона',
					'Да', function()
							net.Start("metadmin.qaction")
								net.WriteInt(2,5)
								net.WriteInt(id,32)
							net.SendToServer()
							timer.Simple(0.25,function()
								metadmin.questionslist()
							end)
					end,
					'Нет', function() metadmin.questionslist() end
				)
				Frame:Close()
			end)
			row:SetIcon("icon16/table_delete.png")
		end

		local row = menu:AddOption("Отмена")
		row:SetIcon("icon16/cancel.png")
		
		menu.Remove = function(m)
			if IsValid(line) then
				line:SetSelected(false)
			end
		end
		menu:Open()
	end
	questionlist:AddColumn("Название")
	for k,v in pairs(metadmin.questions) do
		local line = questionlist:AddLine(v.name)
		line.id = k
		line.enabled = v.enabled
		line.Paint = function(self,w,h)
			surface.SetDrawColor(v.enabled==1 and Color(0,255,0,200) or Color(160,160,160,200))
			surface.DrawRect(0,0,w,h)
		end
	end
end

function metadmin.questionsadd()
	local frame2 = vgui.Create("DFrame")
	frame2:SetSize(400,60)
	frame2:SetTitle("Название шаблона")
	frame2:Center()
	frame2.btnMaxim:SetVisible(false)
	frame2.btnMinim:SetVisible(false)
	local text = vgui.Create("DTextEntry",frame2)
	text:StretchToParent(5,29,5,5)
	text.OnEnter = function()
		local value = text:GetValue()
		net.Start("metadmin.qaction")
			net.WriteInt(4,5)
			net.WriteInt(0,32)
			net.WriteString(value)
		net.SendToServer()
		timer.Simple(0.25,function()
			metadmin.questionslist()
		end)
		frame2:Remove()
	end
	text:RequestFocus()
	frame2:MakePopup()
end

function metadmin.question(tab)
	local answer = {}
	local maxn = #tab
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle("Вопросы ("..maxn..")")
	Frame:ShowCloseButton(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790, 20+40*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k, v in pairs(tab) do
		local question = vgui.Create("DLabel",DPanel)
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		question:SetText((isstring(v) and v or v.question)..":")
		if istable(v) then
			answer[k] = vgui.Create("DComboBox",DPanel)
			answer[k]:SetColor(color_black)
			answer[k]:SetPos(5,25+num*40)
			answer[k]:SetSize(760,20)
			for k2, v2 in pairs(v.answers) do
				answer[k]:AddChoice(v2)
			end
		else
			answer[k] = vgui.Create("DTextEntry",DPanel)
			answer[k]:SetPos(5,25+num*40)
			answer[k]:SetSize(760,20)
		end
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText("Отправить")
	send:SetSize(790,20)
	send.DoClick = function()
		local answers = {}
		for k, v in pairs(answer) do
			answers[k] = answer[k]:GetValue()
		end
		net.Start("metadmin.answers")
			net.WriteTable(answers)
		net.SendToServer()
		Frame:Close()
	end
end

function metadmin.viewanswers(tab)
	if not tab then return end
	local maxn = #tab.questions
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,80+40*maxn))
	Frame:SetTitle("Ответы игрока "..tab.nick.."("..tab.sid..")")
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,60+40*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+40*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k=1,maxn do
		local question = vgui.Create("DLabel",DPanel)
		question:SetSize(760,20)
		question:SetPos(5,5+num*40)
		local quest = tab.questions[k]
		question:SetText((isstring(quest) and quest or quest.question)..":")
		local answer = vgui.Create("DTextEntry",DPanel)
		answer:SetPos(5,25+num*40)
		answer:SetSize(760,20)
		answer:SetText(tab.answers[k] or "ОШИБКА")
		answer:SetEditable(false)
		num = num+1
	end
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,55+40*maxn))
	send:SetText("Обратно в меню")
	send:SetSize(790,20)
	send.DoClick = function()
		Frame:Close()
		metadmin.menu()
	end
end

function metadmin.questions2(id,type,ply)
	local tab = metadmin.questions[id].questions
	if not tab then return end
	local maxn = #tab
	local questions2 = {}
	local Frame = vgui.Create("DFrame")
	Frame:SetSize(800,math.min(600,70+20*maxn))
	Frame:SetTitle(type == "edit"and"Редактирование шаблона вопросов "or"Шаблон вопросов "..metadmin.questions[id].name)
	Frame.btnMaxim:SetVisible(false)
	Frame.btnMinim:SetVisible(false)
	Frame:SetDraggable(true)
	Frame:Center()
	Frame:MakePopup()
	local DScrollPanel = vgui.Create("DScrollPanel",Frame)
	DScrollPanel:SetSize(790,math.min(540,45+20*maxn))
	DScrollPanel:SetPos(1,25)
	local DPanel = vgui.Create("DPanel",DScrollPanel)
	DPanel:SetPos(5,5)
	DPanel:SetSize(790,20+20*maxn)
	DLabel:SetDark(1)
	local num = 0
	for k, v in pairs(tab) do
		if type == "edit" then
			questions2[k] = vgui.Create("DTextEntry",DPanel)
			questions2[k]:SetSize(760,20)
			questions2[k]:SetPos(5,5+num*20)
			questions2[k]:SetText(isstring(v) and v or v.question)
		else
			local question = vgui.Create("DLabel",DPanel)
			question:SetSize(760,20)
			question:SetPos(5,5+num*20)
			question:SetText(k.."."..(isstring(v) and v or v.question))
			if istable(v) then
				for k2,v2 in pairs(v.answers) do
					local answer = vgui.Create("DLabel",DPanel)
					answer:SetSize(760,20)
					answer:SetPos(15,25+num*20)
					answer:SetText(k2.."."..v2)
					num = num + 1
				end
			end
		end
		num = num+1
	end
	Frame:SetSize(800,math.min(600,70+20*num))
	DScrollPanel:SetSize(790,math.min(540,50+20*num))
	DPanel:SetSize(790,10+20*num)
	local send = vgui.Create("DButton",Frame)
	send:SetPos(5,math.min(575,45+20*num))
	send:SetText(type == "edit" and "Сохранить" or ply and "Отправить игроку "..ply.nick or "Обратно в меню")
	send:SetSize(790,20)
	if type == "edit" then
		local DPanel2 = vgui.Create("DPanel",Frame)
		DPanel2:SetPos(718,2)
		DPanel2:SetSize(37,18)
		local add = vgui.Create("DImage",DPanel2)
		add:SetPos(1,1)
		add:SetSize(16,16)
		add:SetImage("icon16/add.png")
		add:SetToolTip("Добавить")
		add:SetMouseInputEnabled(true)
		function add:OnCursorEntered()
			self:SetCursor("hand")
		end
		function add:OnCursorExited()
			self:SetCursor("arrow")
		end
		function add:OnMouseReleased(code)
			local k = #questions2 + 1
			Frame:SetSize( 800, math.min(600,80+20*k) )
			DScrollPanel:SetSize( 790, math.min(540,60+20*k) )
			DPanel:SetSize( 790, 20+20*k )
			send:SetPos( 5, math.min(575,55+20*k))
			questions2[k] = vgui.Create( "DTextEntry", DPanel )
			questions2[k]:SetSize( 760, 20 )
			questions2[k]:SetPos( 5, 5 + (k-1)*20 )
			questions2[k]:SetText("Новое поле")
		end
		
		local rem = vgui.Create("DImage",DPanel2)
		rem:SetPos(20,1)
		rem:SetSize(16,16)
		rem:SetImage("icon16/delete.png")
		rem:SetToolTip("Удалить")
		rem:SetMouseInputEnabled(true)
		function rem:OnCursorEntered()
			self:SetCursor("hand")
		end
		function rem:OnCursorExited()
			self:SetCursor("arrow")
		end
		function rem:OnMouseReleased(code)
			local k = #questions2 -1
			if IsValid(questions2[k+1]) then
				Frame:SetSize( 800, math.min(600,80+20*k) )
				DScrollPanel:SetSize( 790, math.min(540,60+20*k) )
				DPanel:SetSize( 790, 20+20*k )
				send:SetPos( 5, math.min(575,55+20*k))
				questions2[k+1]:Remove()
				questions2[k+1] = nil
			end
		end
	end
	send.DoClick = function()
		if type == "edit" then
			local tab2 = {}
			for k, v in pairs(questions2) do
				tab2[k] = v:GetValue()
			end
			net.Start("metadmin.qaction")
				net.WriteInt(3,5)
				net.WriteInt(id,32)
				net.WriteTable(tab2)
			net.SendToServer()
			Frame:Close()
			metadmin.questionslist()
		else
			if ply then
				net.Start("metadmin.action")
					net.WriteString(ply.sid)
					net.WriteInt(3,5)
					net.WriteString(id)
				net.SendToServer()
			else
				metadmin.questionslist()
			end
			Frame:Close()
		end
	end
end