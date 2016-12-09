metadmin.players = metadmin.players or {}

do
	if not sql.TableExists("ma_answers") then
		sql.Query([[CREATE TABLE `ma_answers` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` int(11) NOT NULL,
		`questions` text NOT NULL,
		`status` int(11) NOT NULL DEFAULT (0),
		`answers` text NOT NULL,
		`time` int(11) NOT NULL,
		`admin` text NOT NULL,
		`ssadmin` text NOT NULL DEFAULT ''
		)]])
	end
	if not sql.TableExists("ma_examinfo") then
		sql.Query([[CREATE TABLE `ma_examinfo` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` int(11) NOT NULL,
		`rank` text NOT NULL,
		`examiner` text NOT NULL,
		`note` text NOT NULL,
		`type` int(11) NOT NULL,
		`server` text NOT NULL
		)]])
	end
	if not sql.TableExists("ma_players") then
		sql.Query([[CREATE TABLE `ma_players` (
		`SID` SID text NOT NULL UNIQUE,
		`group` text NOT NULL,
		`status` text NOT NULL,
		`nick` text NOT NULL DEFAULT '',
		`synch` int(1) NOT NULL DEFAULT (0),
		`synchgroup` text NOT NULL DEFAULT ''
		)]])
	end
	if not sql.TableExists("ma_questions") then
		sql.Query([[CREATE TABLE `ma_questions` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`name` text NOT NULL,
		`questions` text NOT NULL,
		`timelimit` int(11) NOT NULL DEFAULT (0),
		`enabled` int(1) NOT NULL DEFAULT (0)
		)]])
	end
	if not sql.TableExists("ma_violations") then
		sql.Query([[CREATE TABLE `ma_violations` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` int(11) NOT NULL,
		`admin` text NOT NULL,
		`server` text NOT NULL,
		`violation` text NOT NULL
		)]])
	end
end

function metadmin.UpdateBD()
	if sql.TableExists("answers") then
		metadmin.print("Копирование таблицы \"answers\"")
		local results = sql.Query("SELECT * FROM `answers`")
		if results != nil and #results > 0 then
			for k,v in pairs(results) do
				sql.Query("INSERT INTO `ma_answers` (`id`,`SID`,`date`,`questions`,`status`,`answers`,`admin`,`ssadmin`) VALUES (NULL,'"..v.sid.."','"..v.date.."','"..v.questions.."',"..v.status..","..v.answers..","..v.admin..","..v.ssadmin..")")
			end
		end
		metadmin.print("Таблица \"answers\" скопирована")
	end
	if sql.TableExists("examinfo") then
		metadmin.print("Копирование таблицы \"examinfo\"")
		local results = sql.Query("SELECT * FROM `examinfo`")
		if results != nil and #results > 0 then
			for k,v in pairs(results) do
				sql.Query("INSERT INTO `ma_examinfo` (`id`,`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES (NULL,'"..v.sid.."','"..v.date.."','"..v.rank.."',"..v.examiner..","..v.note..","..v.type..","..v.server..")")
			end
		end
		metadmin.print("Таблица \"examinfo\" скопирована")
	end
	if sql.TableExists("players") then
		metadmin.print("Копирование таблицы \"players\"")
		local results = sql.Query("SELECT * FROM `players`")
		if results != nil and #results > 0 then
			for k,v in pairs(results) do
				sql.Query("INSERT OR IGNORE INTO `ma_players` (`SID`,`group`,`status`,`nick`) VALUES ('"..v.SID.."','"..v.group.."','"..v.status.."','"..v.Nick.."')")
			end
		end
		metadmin.print("Таблица \"players\" скопирована")
	end
	if sql.TableExists("questions") then
		metadmin.print("Копирование таблицы \"questions\"")
		local results = sql.Query("SELECT * FROM `questions`")
		if results != nil and #results > 0 then
			for k,v in pairs(results) do
				sql.Query("INSERT INTO `ma_questions` (`id`,`name`,`questions`,`timelimit`,`enabled`) VALUES (NULL,'"..v.name.."','"..v.questions.."',0,"..v.enabled..")")
			end
		end
		metadmin.print("Таблица \"questions\" скопирована")
	end
	if sql.TableExists("violations") then
		metadmin.print("Копирование таблицы \"violations\"")
		local results = sql.Query("SELECT * FROM `violations`")
		if results != nil and #results > 0 then
			for k,v in pairs(results) do
				sql.Query("INSERT INTO `ma_violations` (`id`,`SID`,`date`,`admin`,`server`,`violation`) VALUES (NULL,'"..v.SID.."','"..v.date.."','"..v.admin.."',"..v.server..",'"..v.violation.."')")
			end
		end
		metadmin.print("Таблица \"violations\" скопирована")
	end
end

function metadmin.GetData(sid,cb)
    local result = sql.Query("SELECT * FROM `ma_players` WHERE SID='"..sid.."'")
	cb(result)
end

function metadmin.SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
	sql.Query("UPDATE `ma_players` SET `group` = '"..rank.."',`status` = '"..status.."' WHERE `SID`="..sql.SQLStr(sid))
end

function metadmin.UpdateNick(ply)
	local sid = ply:SteamID()
	if not metadmin.players[sid] then return end
	sql.Query("UPDATE `ma_players` SET `nick` = "..sql.SQLStr(ply:Nick()).." WHERE `SID`='"..sid.."'")
end

function metadmin.OnOffSynch(sid,on)
	if not metadmin.players[sid] or not isnumber(on) then return end
	sql.Query("UPDATE `ma_players` SET `synch` = "..on..",`synchgroup` = '' WHERE `SID`='"..sid.."'")
end

function metadmin.SetSynchGroup(sid,rank)
	sql.Query("UPDATE `ma_players` SET `synchgroup` = "..sql.SQLStr(rank).." WHERE `SID`='"..sid.."'")
end

function metadmin.CreateData(sid)
	local status = "{\"date\":"..os.time()..",\"nom\":1,\"admin\":\"\"}"
	local group = "user"
	local Nick = ""
	local ply = player.GetBySteamID(sid)
	if ply then
		Nick = ply:Nick()
		if metadmin.groupwrite then
			group = ply:GetUserGroup()
		else
			metadmin.setulxrank(ply,group)
		end
	end
	sql.Query("INSERT INTO `ma_players` (`SID`,`group`,`status`,`nick`) VALUES ('"..sid.."','"..group.."','"..status.."',"..sql.SQLStr(Nick)..")")
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = group
	metadmin.players[sid].nick = Nick
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = os.time()
	metadmin.players[sid].violations = {}
	metadmin.players[sid].exam = {}
	metadmin.players[sid].exam_answers = {}
	if metadmin.synch then
		metadmin.OnOffSynch(sid,1)
		metadmin.GetDataSID(sid)
	end
end

function metadmin.GetQuestions(cb)
    local result = sql.Query("SELECT * FROM ma_questions")
	if not result then result = {} end
	cb(result)
end

function metadmin.SaveQuestion(id,questions,enabled)
	local table = ""
	if questions then
		table = "`questions` = '"..questions.."'"
	end
	local enbl = ""
	if enabled then
		enbl = "`enabled` = '"..enabled.."'"
		if questions then questions = questions.."," end
	end
   sql.Query("UPDATE `ma_questions` SET "..table..enbl.." WHERE `id`="..tonumber(id))
end

function metadmin.SaveQuestionName(id,name)
   sql.Query("UPDATE `ma_questions` SET `name` = '"..name.."' WHERE `id`="..tonumber(id))
end

function metadmin.SaveQuestionRecTime(id,time)
   sql.Query("UPDATE `ma_questions` SET `timelimit` = '"..tonumber(time).."' WHERE `id`="..tonumber(id))
end

function metadmin.RemoveQuestion(id)
  sql.Query("DELETE FROM `ma_questions` WHERE `id`='"..id.."'")
end

function metadmin.AddQuestion(name)
	sql.Query("INSERT INTO `ma_questions` (`id`,`name`,`questions`,`enabled`) VALUES (NULL,"..sql.SQLStr(name)..",'{}','0')")
end

function metadmin.GetTests(sid,cb)
	local result = sql.Query("SELECT * FROM ma_answers WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} else
		for k,v in pairs(result) do
			result[k].status = tonumber(result[k].status) 
		end
	end
	cb(result)
end

function metadmin.AddTest(sid,ques,ans,time,adminsid)
	sql.Query("INSERT INTO `ma_answers` (`id`,`SID`,`date`,`questions`,`answers`,`admin`,`time`,`ssadmin`) VALUES (NULL,'"..sid.."','"..os.time().."','"..tonumber(ques).."',"..sql.SQLStr(ans)..",'"..adminsid.."','"..tonumber(time).."','')")
end

function metadmin.SetStatusTest(id,status,ssadmin)
	sql.Query("UPDATE `ma_answers` SET `status` = '"..status.."',`ssadmin` = '"..ssadmin.."' WHERE `id`='"..tonumber(id).."'")
end

function metadmin.GetViolations(sid,cb)
	local result = sql.Query("SELECT * FROM `ma_violations` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end

function metadmin.AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	result = sql.Query("INSERT INTO `ma_violations` (`id`,`SID`,`date`,`admin`,`server`,`violation`) VALUES (NULL,'"..sid.."','"..os.time().."','"..adminsid.."','"..metadmin.server.."',"..sql.SQLStr(violation)..")")
end

function metadmin.RemoveViolation(id)
	sql.Query("DELETE FROM `ma_violations` WHERE `id`="..id)
end

function metadmin.GetExamInfo(sid,cb)
	local result = sql.Query("SELECT * FROM  `ma_examinfo` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end
function metadmin.AddExamInfo(sid,rank,adminsid,note,type)
	sql.Query("INSERT INTO `ma_examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..sid.."','"..os.time().."','"..rank.."','"..adminsid.."',"..sql.SQLStr(note)..",'"..type.."','"..metadmin.server.."')")
end

function metadmin.AllPlayers(group,cb)
	local result = sql.Query("SELECT SID, nick FROM `ma_players` WHERE `synchgroup`='"..group.."' OR (`group`='"..group.."' AND `synchgroup`='')")
	if not result then result = {} end
	cb(result)
end
