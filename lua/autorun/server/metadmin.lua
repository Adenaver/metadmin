metadmin = metadmin or {}
metadmin.category = "MetAdmin" -- Категория в ulx
metadmin.provider = "sql" -- mysql,sql
metadmin.api_key = ""
metadmin.version = "03/05/2016"

if metadmin.provider == "mysql" then
	metadmin.mysql = {}
	metadmin.mysql.host = "localhost" -- Хост
	metadmin.mysql.user = "root" -- Пользователь
	metadmin.mysql.pass = "" -- Пароль
	metadmin.mysql.database = "" -- Название базы данных
	metadmin.mysql.port = 3306 -- Порт
end

local path = "metadmin/providers/"..metadmin.provider..".lua"
if not file.Exists(path, "LUA") then
	error("Не найдено. "..path)
	return
end
include(path)
metadmin.senduser = {"ranks","prom","dem","plombs","pogona"}
metadmin.sendadm = {"server","groupwrite","disps","showserver","voice"}

metadmin.defserver = "SERVER"
metadmin.defgroupwrite = false 
metadmin.defdisps = {["traindispather"]=true}
metadmin.defshowserver = false
metadmin.defranks = {
	["driver3class"] = "Машинист 3 класса",
	["driver2class"] = "Машинист 2 класса",
	["driver1class"] = "Машинист 1 класса",
	["user"] = "Помощник машиниста",
	["auditor"] = "Ревизор",
	["traindispather"] = "Поездной диспетчер",
	["chiefinstructor"] = "Главный инструктор",
	["instructor"] = "Машинист инструктор",
	["superadmin"] = "Начальник метрополитена",
	["developer"] = "Разработчик"
}
metadmin.defprom = {
	["user"] = "driver3class",
	["driver3class"] = "driver2class",
	["driver2class"] = "driver1class"
}
metadmin.defdem = {
	["driver3class"] = "user",
	["driver2class"] = "driver3class",
	["driver1class"] = "driver2class"
}
metadmin.defplombs = {
	["KAH"] = "КАХ",
	["VAH"] = "ВАХ",
	["VAD"] = "ВАД",
	["RC1"] = "РЦ-1",
	["UOS"] = "РЦ-УОС",
	["OtklAVU"] = "ОтклАВУ",
	["A5"] = "A5"
}
metadmin.defpogona = {}
local function start()
	if not file.Exists("metadmin","DATA") then
		file.CreateDir("metadmin")
	end
	if not file.Exists("metadmin/version.txt","DATA") then
		file.Write("metadmin/version.txt",metadmin.version)
		if metadmin.sqlfix then
			metadmin.sqlfix()
		end
	else
		local version = file.Read("metadmin/version.txt","DATA")
		if version != metadmin.version then
			file.Write("metadmin/version.txt",metadmin.version)
			if metadmin.sqlfix then
				metadmin.sqlfix()
			end
		end
	end
	if not file.Exists("metadmin/settings.txt","DATA") then
		local tab = {}
		for k,v in pairs(metadmin.senduser) do
			metadmin[v] = metadmin["def"..v]
			tab[v] = metadmin["def"..v]
		end
		for k,v in pairs(metadmin.sendadm) do
			metadmin[v] = metadmin["def"..v]
			tab[v] = metadmin["def"..v]
		end
		file.Write("metadmin/settings.txt",util.TableToJSON(tab))
	else
		local tab = util.JSONToTable(file.Read("metadmin/settings.txt","DATA"))
		for k,v in pairs(metadmin.senduser) do
			if tab[v] then
				metadmin[v] = tab[v]
			else
				metadmin[v] = metadmin["def"..v]
			end
		end
		for k,v in pairs(metadmin.sendadm) do
			if tab[v] then
				metadmin[v] = tab[v]
			else
				metadmin[v] = metadmin["def"..v]
			end
		end
	end
	http.Fetch("http://metrostroi.net/api/metadmin_version",function(body,len,headers,code) if metadmin.version != body then metadmin.notifver = body end end)
end
start()

util.AddNetworkString("metadmin.profile")
util.AddNetworkString("metadmin.violations")
util.AddNetworkString("metadmin.questions")
util.AddNetworkString("metadmin.answers")
util.AddNetworkString("metadmin.viewanswers")
util.AddNetworkString("metadmin.action")
util.AddNetworkString("metadmin.qaction")
util.AddNetworkString("metadmin.questionstab")
util.AddNetworkString("metadmin.notify")
util.AddNetworkString("metadmin.order")
util.AddNetworkString("metadmin.settings")
util.AddNetworkString("metadmin.report")
util.AddNetworkString("metadmin.allplayers")
util.AddNetworkString("metadmin.synch")
util.AddNetworkString("metadmin.trserver")

for k,v in pairs(metadmin.pogona) do
	resource.AddFile(v)
end

metadmin.questions = metadmin.questions or {}
hook.Add("InitPostEntity","MetAdminInit",function()
	ULib.ucl.registerAccess("ma.pl", ULib.ACCESS_SUPERADMIN, "Возможность открывать меню с игроками.",metadmin.category)
	ULib.ucl.registerAccess("ma.offmenu", ULib.ACCESS_SUPERADMIN, "Возможность открывать меню с оффлайн игроками.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsmenu", ULib.ACCESS_SUPERADMIN, "Возможность открывать меню вопросов.",metadmin.category)
	for k, v in pairs(metadmin.prom) do
		ULib.ucl.registerAccess("ma.prom"..v, ULib.ACCESS_SUPERADMIN, "Доступ к выдаче ранга '"..metadmin.ranks[v]..".",metadmin.category)
	end
	ULib.ucl.registerAccess("ma.questionscreate", ULib.ACCESS_SUPERADMIN, "Создание шаблона с вопросами.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsedit", ULib.ACCESS_SUPERADMIN, "Редактирование шаблона с вопросами'.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsremove", ULib.ACCESS_SUPERADMIN, "Удаление шаблона с вопросами.",metadmin.category)
	ULib.ucl.registerAccess("ma.questionsimn", ULib.ACCESS_SUPERADMIN, "Добавление/удаление шаблона из меню.",metadmin.category)
	ULib.ucl.registerAccess("ma.starttest", ULib.ACCESS_SUPERADMIN, "Доступ к 'Начать тест'.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewresults", ULib.ACCESS_SUPERADMIN, "Просмотр рельзутатов теста.",metadmin.category)
	ULib.ucl.registerAccess("ma.promote", ULib.ACCESS_SUPERADMIN, "Повышение ранга игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.demote", ULib.ACCESS_SUPERADMIN, "Понижение ранга игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.examinfo", ULib.ACCESS_SUPERADMIN, "Просмотр информации о экзаменах.",metadmin.category)
	ULib.ucl.registerAccess("ma.violationgive", ULib.ACCESS_SUPERADMIN, "Выдача нарушения игроку.",metadmin.category)
	ULib.ucl.registerAccess("ma.violationremove", ULib.ACCESS_SUPERADMIN, "Удаление нарушения игроку.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewviolations", ULib.ACCESS_SUPERADMIN, "Просмотр нарушений игрока.",metadmin.category)
	ULib.ucl.registerAccess("ma.taketalon", ULib.ACCESS_SUPERADMIN, "Возращение талон.",metadmin.category)
	ULib.ucl.registerAccess("ma.givetalon", ULib.ACCESS_SUPERADMIN, "Отбирание талона.",metadmin.category)
	ULib.ucl.registerAccess("ma.viewtalon", ULib.ACCESS_SUPERADMIN, "Просмотр талона.",metadmin.category)
	ULib.ucl.registerAccess("ma.setstattest", ULib.ACCESS_SUPERADMIN, "Установка статуса теста.",metadmin.category)
	ULib.ucl.registerAccess("ma.forcesetstattest", ULib.ACCESS_SUPERADMIN, "Установка статуса теста.(Без проверки)",metadmin.category)
	ULib.ucl.registerAccess("ma.order", ULib.ACCESS_SUPERADMIN, "Доступ к приказам.",metadmin.category)
	ULib.ucl.registerAccess("ma.settings", ULib.ACCESS_SUPERADMIN, "Доступ к настройкам.",metadmin.category)
	ULib.ucl.registerAccess("ma.synch", ULib.ACCESS_SUPERADMIN, "Включение/выключение синхронизации игрока с сайтом.",metadmin.category)
	ULib.ucl.registerAccess("ma.refsynch", ULib.ACCESS_SUPERADMIN, "Обновить данные игрока с сайта.",metadmin.category)
	timer.Simple(2.5, function()
		metadmin.GetQuestions(
			function(data)
				for k, v in pairs(data) do
					id = tonumber(v.id)
					metadmin.questions[id] = {}
					metadmin.questions[id].name = v.name
					metadmin.questions[id].questions = util.JSONToTable(v.questions)
					metadmin.questions[id].enabled = tonumber(v.enabled)
				end
			end
		)
	end)
end)
function metadmin.Notify(target,...)
	net.Start("metadmin.notify")
		net.WriteTable({...})
	if not target then
		net.Broadcast()
	else
		net.Send(target)
	end
end

function metadmin.Log(str)
	file.Append("metadmin/log.txt","["..os.date( "%X - %d/%m/%Y",os.time()).."] "..str.."\r\n")
end

hook.Add('MetrostroiPlombBroken', 'MetAdmin', function(train,but,drv)
	local ply = train:GetDriver()
	if ply.plombs[but] then
		ply.plombs[but] = nil
	else
		but = metadmin.plombs and metadmin.plombs[but] or but
		local str = ply:Nick().." cорвал пломбу с "..but.." без разрешения диспетчера."
		metadmin.Notify(false,Color(129,207,224),str)
		metadmin.Log(str)
		metadmin.AddViolation(ply:SteamID(),nil,"Cорвал пломбу с "..but.." без разрешения диспетчера.")
		if metadmin.players[ply:SteamID()].synch then return end
		metadmin.GetViolations(ply:SteamID(), function(data)
			metadmin.players[ply:SteamID()].violations = data
		end)
	end
end)
local function spawn(ply)
	if ULib.ucl.query(ply,"ma.pl") then
		net.Start("metadmin.questionstab")
			net.WriteTable(metadmin.questions)
		net.Send(ply)
	end
end

function metadmin.SendSettings(ply)
	local tab = {}
	for k,v in pairs(metadmin.senduser) do
		tab[v] = metadmin[v]
	end
	if ULib.ucl.query(ply,"ma.settings") then
		for k,v in pairs(metadmin.sendadm) do
			tab[v] = metadmin[v]
		end
	end
	net.Start("metadmin.settings")
		net.WriteTable(tab)
	net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "metadmin", function(ply)
	metadmin.GetDataSID(ply:SteamID())
	spawn(ply)
	metadmin.SendSettings(ply)
	ply.plombs = {}
	if ply:IsAdmin() and metadmin.notifver then
		timer.Simple(2,function()
			metadmin.Notify(ply,Color(129,207,224),"Доступно обновление MetAdmin!")
			metadmin.Notify(ply,Color(129,207,224),"Текущая версия: ",Color(0,102,255),metadmin.version)
			metadmin.Notify(ply,Color(129,207,224),"Актуальная версия: ",Color(0,102,255),metadmin.notifver)
		end)
	end
end)

hook.Add(ULib.HOOK_PLAYER_NAME_CHANGED,"metadmin",function(ply,LastNick,Nick)
	metadmin.UpdateNick(ply)
	metadmin.players[ply:SteamID()].Nick = Nick
end)

function refreshquestions()
	metadmin.GetQuestions(
		function(data)
			metadmin.questions = {}
			for k, v in pairs(data) do
				id = tonumber(v.id)
				metadmin.questions[id] = {}
				metadmin.questions[id].name = v.name
				metadmin.questions[id].questions = util.JSONToTable(v.questions)
				metadmin.questions[id].enabled = tonumber(v.enabled)
			end
			for k, v in pairs(player.GetAll()) do
				spawn(v)
			end
		end
	)
end

local function GetNick(sid,def)
	local nick = (ULib.ucl.users[sid] and ULib.ucl.users[sid].name) or def
	local ply = player.GetBySteamID(sid)
	if ply then
		nick = ply:Nick()
	end
	return nick
end
local status = {[0]="На проверке","Сдал","Не сдал"}
net.Receive("metadmin.action", function(len,ply)
	if not ULib.ucl.query(ply,"ma.pl") then return end
	local sid = net.ReadString()
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	local action = net.ReadInt(5)
	local str = net.ReadString()
	if action == 1 and ULib.ucl.query(ply,"ma.promote") then
		metadmin.promotion(ply,sid,str)
	elseif action == 2 and ULib.ucl.query(ply,"ma.demote") then
		metadmin.demotion(ply,sid,str)
	elseif action == 3 and ULib.ucl.query(ply,"ma.starttest") then
		metadmin.sendquestions(ply,sid,tonumber(str))
	elseif action == 4 and ULib.ucl.query(ply,"ma.viewresults") then
		metadmin.view_answers(ply,sid,tonumber(str))
	elseif action == 5 and ULib.ucl.query(ply,"ma.setstattest") then
		local stat = net.ReadInt(4)
		local tab = metadmin.players[sid].exam_answers
		local answers_tab = {}
		for k,v in pairs(tab) do
			answers_tab = v
		end
		if (answers_tab.ssadmin != "" and answers_tab.ssadmin != ply:SteamID()) and not ULib.ucl.query(ply,"ma.forcesetstattest") then metadmin.Notify(ply,Color(129,207,224),"Вы не можете изменить статус теста!") return end
		metadmin.SetStatusTest(str,stat,ply:SteamID())
		metadmin.GetTests(sid, function(data)
			metadmin.players[sid].exam_answers = data
		end)
		metadmin.Notify(ply,"Статус изменен")
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.Notify(target,Color(129,207,224),ply:Nick().." установил статус \""..status[stat].."\" на Ваш тест ("..metadmin.questions[tonumber(answers_tab.questions)].name..")")
		end
	elseif action == 7 and ULib.ucl.query(ply,"ma.givetalon") then
		metadmin.settalon(ply,sid,1)
	elseif action == 8 and ULib.ucl.query(ply,"ma.taketalon") then
		metadmin.settalon(ply,sid,2,str)
	end
end)

net.Receive("metadmin.settings", function(len, ply)
	if not ULib.ucl.query(ply,"ma.settings") then return end
	for k,v in pairs(net.ReadTable()) do
		metadmin[k] = v
	end
	local tab = {}
	for k,v in pairs(metadmin.senduser) do
		tab[v] = metadmin[v]
	end
	for k,v in pairs(metadmin.sendadm) do
		tab[v] = metadmin[v]
	end
	
	file.Write("metadmin/settings.txt",util.TableToJSON(tab))
	metadmin.SendSettings(ply)
end)

net.Receive("metadmin.order", function(len, ply)
	if not ULib.ucl.query(ply,"ma.order") then return end
	local tar = net.ReadEntity()
	local plomb = net.ReadString()
	if not metadmin.plombs[plomb] then return end
	tar.plombs[plomb] = true
	local str = ply:Nick().." разрешил "..tar:Nick().." сорвать пломбу с "..metadmin.plombs[plomb]
	metadmin.Notify(false,Color(129,207,224),str)
	metadmin.Log(str)
end)

net.Receive("metadmin.report",function(len,ply)
end)

net.Receive("metadmin.allplayers", function(len, ply)
	if not ULib.ucl.query(ply,"ma.pl") or not ULib.ucl.query(ply,"ma.offmenu") then return end
	local group = net.ReadString()
	if not metadmin.ranks[group] then return end
	if group == "user" then return end
	metadmin.AllPlayers(group,function(cb)
		local tab = {}
		for k,v in pairs(cb) do
			tab[k] = {}
			tab[k].nick = v.Nick
			tab[k].SID = v.SID
		end
		net.Start("metadmin.allplayers")
			net.WriteTable(tab)
		net.Send(ply)
	end)
end)

net.Receive("metadmin.synch", function(len, ply)
	local ref = net.ReadBool()
	local sid = net.ReadString()
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") or not metadmin.players[sid] then return end
	if not ref and ULib.ucl.query(ply,"ma.synch") then
		metadmin.OnOffSynch(sid,metadmin.players[sid].synch and 0 or 1)
		metadmin.GetDataSID(sid)
	elseif ref and metadmin.players[sid].synch and ULib.ucl.query(ply,"ma.refsynch") then
		metadmin.GetDataSID(sid)
		metadmin.Notify(ply,Color(129,207,224),"Данные обновлены")
	end
end)


local talons = {[1]="зеленый",[2]="желтый",[0]="красный"}
function metadmin.settalon(ply,sid,type,reason)
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
		if metadmin.players[sid].status.nom == "Пле" then return end
		if type == 2 then
			if metadmin.players[sid].status.nom + 1 <= 3 then
				metadmin.players[sid].status.nom = metadmin.players[sid].status.nom + 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ply:SteamID()
				metadmin.Notify(ply,Color(129,207,224),"Вы успешно отобрали талон.")
				metadmin.Log(ply:Nick().." отобрал талон у игрока "..sid)
				metadmin.SaveData(sid)
			elseif metadmin.players[sid].status.nom + 1 > 3 then
				metadmin.players[sid].status.nom = 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ""
				local target = player.GetBySteamID(sid)
				if target then
					metadmin.setulxrank(target,newgroup)
				end
				metadmin.AddExamInfo(sid,"user","CONSOLE",ply:Nick().." ("..ply:SteamID()..") отобрал красный талон.\nУВОЛЕН!",2)
				metadmin.players[sid].rank = "user"
				metadmin.SaveData(sid)
				metadmin.GetExamInfo(sid, function(data)
					metadmin.players[sid].exam = data
				end)
			end
			if reason then
				metadmin.violationgive(ply,sid,"Забрал "..talons[metadmin.players[sid].status.nom - 1].." талон.\n"..reason)
			end
		else
			if metadmin.players[sid].status.nom - 1 > 0 then
				metadmin.players[sid].status.nom = metadmin.players[sid].status.nom - 1
				metadmin.players[sid].status.date = os.time()
				metadmin.players[sid].status.admin = ply:SteamID()
				metadmin.Notify(ply,Color(129,207,224),"Вы успешно вернули талон.")
				metadmin.Log(ply:Nick().." вернул талон игроку "..sid)
				metadmin.SaveData(sid)
			end
		end
	else
		metadmin.GetDataSID(sid,function() metadmin.settalon(ply,sid,type,reason) end)
	end
end

net.Receive("metadmin.violations",function(len,ply)
	if not ULib.ucl.query(ply,"ma.viewviolations") then return end
	local action = net.ReadInt(3)
	local sid = net.ReadString()
	local str = net.ReadString()
	if action == 1 and ULib.ucl.query(ply,"ma.violationgive") then
		metadmin.violationgive(ply,sid,str)
	elseif action == 2 and ULib.ucl.query(ply,"ma.violationremove") then
		metadmin.violationremove(ply,sid,str)
	end
end)

function metadmin.violationgive(call,sid,str)
	if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
	metadmin.AddViolation(sid,call:SteamID(),str)
	call:ChatPrint("Нарушение добавлено.")
	metadmin.GetViolations(sid, function(data)
		metadmin.players[sid].violations = data
	end)
end

function metadmin.violationremove(call,sid,id)
	if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
	id = tonumber(id)
	if IsValid(call) then
		metadmin.Notify(call,Color(129,207,224),"Нарушение удалено.")
	end
	metadmin.RemoveViolation(id)
	metadmin.GetViolations(sid, function(data)
		metadmin.players[sid].violations = data
	end)
end

function metadmin.profile(call,sid)
	if type(sid) != "string" then sid = sid:SteamID() end
	if sid == "" then sid = call:SteamID() end
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end 
	end
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	if metadmin.players[sid] then
		if metadmin.players[sid].nodata then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом. Но что-то пошло не так!") return end
		local tab = {}
		local target = player.GetBySteamID(sid)
		if target == call or ULib.ucl.query(call,"ma.viewviolations") then
			tab.violations = metadmin.players[sid].violations
			if not metadmin.players[sid].synch then
				for k,v in pairs(tab.violations) do
					tab.violations[k].admin = GetNick(v.admin,v.admin)
				end
			end
		end
		if target == call or ULib.ucl.query(call,"ma.examinfo") then
			tab.exam = metadmin.players[sid].exam
			if not metadmin.players[sid].synch then
				for k,v in pairs(tab.exam) do
					tab.exam[k].examiner = GetNick(v.examiner,v.examiner)
				end
			end
		end
		if target == call or ULib.ucl.query(call,"ma.viewtalon") then
			tab.status = metadmin.players[sid].status
			tab.status.admin = GetNick(tab.status.admin,tab.status.admin)
		end
		if target == call or ULib.ucl.query(call,"ma.viewresults") then
			tab.exam_answers = metadmin.players[sid].exam_answers
			for k,v in pairs(tab.exam_answers) do
				v.questions = tonumber(v.questions)
				v.name = (metadmin.questions[v.questions] and metadmin.questions[v.questions].name) or "Шаблон удален"
				v.admin = GetNick(v.admin,v.admin)
				v.ssadmin = GetNick(v.ssadmin,v.ssadmin)
			end
		end
		tab.rank = metadmin.players[sid].rank
		tab.SID = sid
		tab.Nick = metadmin.players[sid].Nick
		if tab.Nick == "" then
			tab.Nick = GetNick(sid,"")
		end
		tab.nvio = #metadmin.players[sid].violations
		tab.badpl = metadmin.players[sid].badpl
		tab.synch = metadmin.players[sid].synch
		tab.icon = metadmin.players[sid].icon
		net.Start("metadmin.profile")
			net.WriteTable(tab)
		net.Send(call)
	else
		metadmin.GetDataSID(sid,function() metadmin.profile(call,sid) end,true)
	end
end

function metadmin.setulxrank(ply,rank)
	local userInfo = ULib.ucl.authed[ply:UniqueID()]
	local id = ULib.ucl.getUserRegisteredID(ply)
	if not id then id = ply:SteamID() end
	ULib.ucl.addUser(id,userInfo.allow,userInfo.deny,rank)
	--ply:SetUserGroup(rank)
	metadmin.SendSettings(ply)
end

function metadmin.setrank(call,sid,rank)
	if type(sid) != "string" then sid = sid:SteamID() end
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then
		for k, v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()),string.lower(sid)) then
				sid = v:SteamID()
			end
		end 
	end
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	if metadmin.players[sid] then
		if metadmin.ranks[rank] and ULib.ucl.groups[rank] then
			if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
			if metadmin.players[sid].rank == rank then metadmin.Notify(call,Color(129,207,224),"Что ты пытаешься сделать? Ранги идентичны!") return end
			metadmin.players[sid].rank = rank
			metadmin.SaveData(sid)
			local target = player.GetBySteamID(sid)
			if target then
				metadmin.setulxrank(target,rank)
				spawn(target)
			end
			local nick = IsValid(call) and call:Nick() or "CONSOLE"
			local steamid = IsValid(call) and call:SteamID() or "CONSOLE"
			local str = nick.." установил ранг игроку "..GetNick(sid,sid).."|"..metadmin.ranks[rank]
			metadmin.Notify(false,Color(129,207,224),str)
			metadmin.Log(str)
			metadmin.AddExamInfo(sid,rank,steamid,"Установка ранга через команду.",3)
			timer.Simple(1,function()
				metadmin.GetExamInfo(sid, function(data)
					metadmin.players[sid].exam = data
				end)
			end)
		else
			metadmin.Notify(call,Color(129,207,224),"Ранг "..rank.." отсутствует в metadmin!")
		end
	else
		metadmin.GetDataSID(sid,function() metadmin.setrank(call,sid,rank) end,true)
	end
end

function metadmin.promotion(call,sid,note)
	if not ULib.ucl.query(call,"ma.promote") then return end
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.prom[group]
		if not newgroup and not ULib.ucl.groups[newgroup] then return end
		if not ULib.ucl.query(call,"ma.prom"..newgroup) then return end
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.setulxrank(target,newgroup)
		end
		local nick = GetNick(sid,sid)
		local str = call:Nick().." повысил игрока "..nick.." до "..metadmin.ranks[newgroup]
		metadmin.Notify(false,Color(129,207,224),str)
		metadmin.Log(str)
		metadmin.AddExamInfo(sid,newgroup,call:SteamID(),note,1)
		metadmin.players[sid].rank = newgroup
		metadmin.SaveData(sid)
		metadmin.GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
		end)
	else
		metadmin.GetDataSID(sid,function() metadmin.promotion(call,sid,note) end)
	end
end
function metadmin.demotion(call,sid,note)
	if not ULib.ucl.query(call,"ma.demote") then return end
	if metadmin.players[sid] then
		if metadmin.players[sid].synch then metadmin.Notify(call,Color(129,207,224),"Данный игрок синхронизируется с сайтом.") return end
		local group = metadmin.players[sid].rank
		local newgroup = metadmin.dem[group]
		if not newgroup and not ULib.ucl.groups[newgroup] then return end
		local target = player.GetBySteamID(sid)
		if target then
			metadmin.setulxrank(target,newgroup)
		end
		local nick = GetNick(sid,sid)
		local str = call:Nick().." понизил игрока "..nick.." до "..metadmin.ranks[newgroup]
		metadmin.Notify(false,Color(129,207,224),str)
		metadmin.Log(str)
		metadmin.AddExamInfo(sid,newgroup,call:SteamID(),note,2)
		metadmin.players[sid].rank = newgroup
		metadmin.SaveData(sid)
		metadmin.GetExamInfo(sid, function(data)
			metadmin.players[sid].exam = data
		end)
	else
		metadmin.GetDataSID(sid,function() metadmin.demotion(call,sid,note) end)
	end
end

net.Receive("metadmin.qaction",function(len,ply)
	if not ULib.ucl.query(ply,"ma.questionsmenu") then return end
	local action = net.ReadInt(5)
	local id = net.ReadInt(32)
	if action == 1 and metadmin.questions[id] and ULib.ucl.query(ply,"ma.questionsimn") then
		if metadmin.questions[id].enabled == 1 then action = "отключен" else action = "включен" end
		metadmin.Notify(ply,Color(129,207,224),"Шаблон "..metadmin.questions[id].name.." успешно "..action)
		metadmin.SaveQuestion(id,nil,metadmin.questions[id].enabled == 1 and 0 or 1)
	elseif action == 2 and metadmin.questions[id] and ULib.ucl.query(ply,"ma.questionsremove") then
		metadmin.Notify(ply,Color(129,207,224),"Шаблон "..metadmin.questions[id].name.." успешно удален")
		metadmin.RemoveQuestion(id)
	elseif action == 3 and metadmin.questions[id] and ULib.ucl.query(ply,"ma.questionsedit") then
		local tab = net.ReadTable()
		metadmin.SaveQuestion(id,util.TableToJSON(tab))
		metadmin.Notify(ply,Color(129,207,224),"Шаблон "..metadmin.questions[id].name.." успешно изменен")
	elseif action == 4 and ULib.ucl.query(ply,"ma.questionscreate") then
		local name = net.ReadString()
		metadmin.AddQuestion(name)
		metadmin.Notify(ply,Color(129,207,224),"Шаблон "..name.." успешно добавлен")
	elseif action == 5 and metadmin.questions[id] and ULib.ucl.query(ply,"ma.questionsedit") then
		metadmin.SaveQuestionName(id,net.ReadString())
		metadmin.Notify(ply,Color(129,207,224),"Шаблон "..metadmin.questions[id].name.." успешно изменен")
	else return end
	refreshquestions()
end)

function metadmin.sendquestions(call,sid,id)
	local target = player.GetBySteamID(sid)
	if target then
		if target == call then metadmin.Notify(call,Color(129,207,224),"Зачем ты пытался отправить тест сам себе? Фу! Фу! Фу!") return end
		if target.anstoques then metadmin.Notify(call,Color(129,207,224),"Игрок еще не ответил на предыдущий тест, который выдал "..target.anstoques.nick) return end
		if not metadmin.questions[id] then return metadmin.Notify(call,Color(129,207,224),"Такого шаблона нет!") end
		if metadmin.questions[id].enabled == 0 then return metadmin.Notify(call,Color(129,207,224),"Этот шаблон отключен!") end
		net.Start("metadmin.questions")
			net.WriteTable(metadmin.questions[id].questions)
		net.Send(target)
		target.anstoques = {}
		target.anstoques.nick = call:Nick()
		target.anstoques.adminsid = call:SteamID()
		target.anstoques.idquestions = id
		target.anstoques.time = os.time()
		local str = call:Nick().." отправил тест ("..metadmin.questions[id].name..") игроку "..target:Nick()
		metadmin.Notify(false,Color(129,207,224),str)
		metadmin.Log(str)
	end
end
function metadmin.view_answers(call,sid,id)
	if metadmin.players[sid] then
		local tab = {}
		for k,v in pairs(metadmin.players[sid].exam_answers) do
			if tonumber(v.id) == id then
				tab.answerstab = v
				tab.answers = util.JSONToTable(v.answers)
			end
		end
		if not tab then return end
		tab.nick = GetNick(sid,"UNKNOWN")
		tab.sid = sid
		tab.questions = metadmin.questions[tonumber(tab.answerstab.questions)].questions
		net.Start("metadmin.viewanswers")
			net.WriteTable(tab)
		net.Send(call)
	else
		metadmin.GetDataSID(sid,function() metadmin.view_answers(call,sid,id) end)
	end
end
net.Receive("metadmin.answers", function(len, ply)
	if not ply.anstoques then return end
	local ans = net.ReadTable()
	if metadmin.questions[ply.anstoques.idquestions].enabled == 0 then return end
	local str = "Игрок "..ply:Nick().." ответил на вопросы теста за "..string.ToMinutesSeconds(os.time()-ply.anstoques.time).." минут. Его результат записан и вскоре будет проверен."
	metadmin.Notify(false,Color(129,207,224),str)
	metadmin.Log(str)
	metadmin.AddTest(ply:SteamID(),ply.anstoques.idquestions,util.TableToJSON(ans),ply.anstoques.adminsid)
	metadmin.GetTests(ply:SteamID(), function(data)
		metadmin.players[ply:SteamID()].exam_answers = data
	end)
	ply.anstoques = false
end)

hook.Add("PlayerSay", "XER", function(ply,text)
	if string.find(text,"Диспетчер",1) then
		for k,v in pairs(player.GetAll()) do
			if metadmin.disps[v:GetUserGroup()] then
				v:PrintMessage(HUD_PRINTCENTER,'Вас вызывают!')
			end
		end
	end
end )


local badpl = true
function metadmin.GetDataSID(sid,cb,nocreate)
	if not string.match(sid,"(STEAM_[0-5]:[01]:%d+)") then return end
	metadmin.GetData(sid, function(data)
		if data and data[1] then
			if tonumber(data[1].synch) == 1 then
				metadmin.players[sid] = {exam = {},exam_answers = {},violations = {},status = {date=0,admin="",nom=1},rank = "user",Nick = "",synch = true,nodata = true}
				http.Fetch("http://metrostroi.net/api/user/"..sid,function(body,len,headers,code)
					if body == "" then
						metadmin.Log("Синхронизация "..sid.." с сайтом невозможна!| Данного игрока на сайте нет!")
						metadmin.OnOffSynch(sid,0)
						metadmin.GetDataSID(sid,cb)
						return
					end
					metadmin.players[sid] = util.JSONToTable(body)
					if not metadmin.ranks[metadmin.players[sid].rank] or not ULib.ucl.groups[metadmin.players[sid].rank] then
						metadmin.Log("Синхронизация "..sid.." с сайтом невозможна!| Ранг "..metadmin.players[sid].rank.." не существует!")
						metadmin.OnOffSynch(sid,0)
						metadmin.GetDataSID(sid,cb)
						return
					end
					if metadmin.players[sid].badpl == "" then
						metadmin.players[sid].badpl = false
					end
					if metadmin.players[sid].Nick == "" then
						metadmin.players[sid].Nick = data[1].Nick
					end
					if data[1].synchgroup != metadmin.players[sid].rank then
						metadmin.SetSynchGroup(sid,metadmin.players[sid].rank)
					end
					metadmin.players[sid].synch = true
					metadmin.GetTests(sid, function(data)
						metadmin.players[sid].exam_answers = data
					end)
					local target = player.GetBySteamID(sid)
					if target then
						if target:Nick() != metadmin.players[sid].Nick then
							if not metadmin.players[sid].synch then
								metadmin.UpdateNick(target)
							end
							metadmin.players[sid].Nick = target:Nick()
						end
						if target:GetUserGroup() != metadmin.players[sid].rank then
							metadmin.setulxrank(target,metadmin.players[sid].rank)
						end
					end
				end)
			else
				metadmin.players[sid] = {}
				if metadmin.ranks[data[1].group] and ULib.ucl.groups[data[1].group] then
					metadmin.players[sid].rank = data[1].group
				else
					metadmin.players[sid].rank = "user"
					metadmin.Log("Невозможно выдать ранг игроку "..sid.." | Такого ранга не существует!")
				end
				metadmin.players[sid].Nick = data[1].Nick
				metadmin.players[sid].status = util.JSONToTable(data[1].status)
				metadmin.GetViolations(sid, function(data)
					metadmin.players[sid].violations = data
				end)
				metadmin.GetExamInfo(sid, function(data)
					metadmin.players[sid].exam = data
				end)
				metadmin.GetTests(sid, function(data)
					metadmin.players[sid].exam_answers = data
				end)
				local target = player.GetBySteamID(sid)
				if target then
					if target:Nick() != metadmin.players[sid].Nick then
						if not metadmin.players[sid].synch then
							metadmin.UpdateNick(target)
						end
						metadmin.players[sid].Nick = target:Nick()
					end
					if target:GetUserGroup() != metadmin.players[sid].rank then
						metadmin.setulxrank(target,metadmin.players[sid].rank)
					end
				end
				http.Fetch("http://metrostroi.net/api/bad/"..sid,function(body,len,headers,code) metadmin.players[sid].badpl = body != "" and body or false end)
				http.Fetch("http://metrostroi.net/api/icon/"..sid,function(body,len,headers,code) metadmin.players[sid].icon = tonumber(body) != "" and body or false end)
			end
			if cb then
				timer.Simple(0.25,function() cb() end)
			end
		else
			if nocreate then return end
			metadmin.CreateData(sid)
		end
	end)
end

hook.Add('PlayerCanHearPlayersVoice', 'metadmin', function(listener,talker)
	if metadmin.voice then
		if listener:IsAdmin() then return true end
		if metadmin.disps[metadmin.players[talker:SteamID()].rank] then
			return true
		end
		if metadmin.disps[metadmin.players[listener:SteamID()].rank] then
			return true
		end
		return false
	end
end)
