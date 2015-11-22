metadmin.players = metadmin.players or {}

local function Start()
	if not sql.TableExists("answers") then
		sql.Query([[CREATE TABLE `answers` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`sid` text NOT NULL,
		`date` text NOT NULL,
		`questions` text NOT NULL,
		`status` int(11) NOT NULL DEFAULT '0',
		`answers` text NOT NULL
		)]])
	end
	if not sql.TableExists("examinfo") then
		sql.Query([[CREATE TABLE `examinfo` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` text NOT NULL,
		`rank` text NOT NULL,
		`examiner` text NOT NULL,
		`note` text NOT NULL,
		`type` int(11) NOT NULL,
		`server` text NOT NULL
		)]])
	end
	if not sql.TableExists("players") then
		sql.Query([[CREATE TABLE `players` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`group` text NOT NULL,
		`status` text NOT NULL
		)]])
	end
	if not sql.TableExists("questions") then
		sql.Query([[CREATE TABLE `questions` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`name` text NOT NULL,
		`questions` text NOT NULL,
		`enabled` int(1) NOT NULL
		)]])
	end
	if not sql.TableExists("violations") then
		sql.Query([[CREATE TABLE `violations` (
		`id` INTEGER PRIMARY KEY AUTOINCREMENT,
		`SID` text NOT NULL,
		`date` text NOT NULL,
		`admin` text NOT NULL,
		`server` text NOT NULL,
		`violation` text NOT NULL
		)]])
	end
end
Start()
function metadmin.GetData(sid,cb)
    local result = sql.Query("SELECT * FROM players WHERE SID='"..sid.."'")
	cb(result)
end

function metadmin.SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
	sql.Query("UPDATE `players` SET `group` = '"..rank.."',`status` = '"..status.."' WHERE `SID`="..sql.SQLStr(sid))
end

function metadmin.CreateData(sid)
	local status = "{\"date\":"..os.time()..",\"nom\":1,\"admin\":\"\"}"
	local group = "user"
	local ply = player.GetBySteamID(sid)
	if ply then
		if metadmin.groupwrite then
			group = ply:GetUserGroup()
		else
			metadmin.setulxrank(ply,group)
		end
	end
	result = sql.Query("INSERT INTO `players` (`id`,`SID`,`group`,`status`) VALUES (NULL,'"..sid.."','"..group.."','"..status.."')")
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = group
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = os.time()
end

function metadmin.GetQuestions(cb)
    local result = sql.Query("SELECT * FROM questions")
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
   sql.Query("UPDATE `questions` SET "..table..enbl.." WHERE `id`="..tonumber(id))
end

function metadmin.RemoveQuestion(id)
  sql.Query("DELETE FROM `questions` WHERE `id`='"..id.."'")
end

function metadmin.AddQuestion(name)
    sql.Query("INSERT INTO `questions` (`id`,`name`,`questions`,`enabled`) VALUES (NULL,"..sql.SQLStr(name)..",'{}','0')")
end

function metadmin.GetTests(sid,cb)
	local result = sql.Query("SELECT * FROM answers WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} else
		for k,v in pairs(result) do
			result[k].status = tonumber(result[k].status) 
		end
	end
	cb(result)
end

function metadmin.AddTest(sid,ques,ans)
	sql.Query("INSERT INTO `answers` (`id`,`sid`,`date`,`questions`,`answers`) VALUES (NULL,'"..sid.."','"..os.time().."','"..tonumber(ques).."',"..sql.SQLStr(ans)..")")
end

function metadmin.SetStatusTest(id,status)
	sql.Query("UPDATE `answers` SET `status` = '"..status.."' WHERE `id`='"..tonumber(id).."'")
end

function metadmin.GetViolations(sid,cb)
	local result = sql.Query("SELECT * FROM `violations` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end

function metadmin.AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	result = sql.Query("INSERT INTO `violations` (`id`,`SID`,`date`,`admin`,`server`,`violation`) VALUES (NULL,'"..sid.."','"..os.time().."','"..adminsid.."','"..metadmin.server.."',"..sql.SQLStr(violation)..")")
end

function metadmin.RemoveViolation(id)
	sql.Query("DELETE FROM `violations` WHERE `id`="..id)
end

function metadmin.GetExamInfo(sid,cb)
	local result = sql.Query("SELECT * FROM  `examinfo` WHERE SID="..sql.SQLStr(sid).." ORDER BY id DESC")
	if not result then result = {} end
	cb(result)
end
function metadmin.AddExamInfo(sid,rank,adminsid,note,type)
	sql.Query("INSERT INTO `examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..sid.."','"..os.time().."','"..rank.."','"..adminsid.."',"..sql.SQLStr(note)..",'"..type.."','"..metadmin.server.."')")
end