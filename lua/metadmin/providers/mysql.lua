require('mysqloo')

local db = mysqloo.connect('localhost', 'root', '', '', 3306) -- Хост,юзер,пароль,название бд, порт

function db:onConnected()
	local utf8 = db:query("SET names 'utf8'")
	utf8:start()
    MsgN('MySQL: Подключено!')
end

function db:onConnectionFailed(err)
    MsgN('MySQL: Ошибка: ' .. err)
end

db:connect()
metadmin.players = metadmin.players or {}

function metadmin.GetData(sid,cb)
    local q = db:query("SELECT * FROM players WHERE SID='"..db:escape(sid).."'")
    q.onSuccess = function(self, data)
		cb(data)
    end
	 
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.SaveData(sid)
	if not metadmin.players[sid] then return end
	local rank = metadmin.players[sid].rank or "user"
	local status = util.TableToJSON(metadmin.players[sid].status)
    local q = db:query("UPDATE `players` SET `group` = '"..rank.."',`status` = '"..status.."' WHERE `SID`='"..db:escape(sid).."'")
     
    function q:onSuccess()
		print("Saved")
    end
	 
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
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
	metadmin.players[sid] = {}
	metadmin.players[sid].rank = group
	metadmin.players[sid].status = {}
	metadmin.players[sid].status.nom = 1
	metadmin.players[sid].status.admin = ""
	metadmin.players[sid].status.date = os.time()
	metadmin.players[sid].violations = {}
	metadmin.players[sid].exam = {}
	metadmin.players[sid].exam_answers = {}
	local q = db:query("INSERT INTO `players` (`SID`,`group`,`status`) VALUES ('"..sid.."','"..group.."','"..status.."')")
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.GetQuestions(cb)
    local q = db:query("SELECT * FROM questions")
    q.onSuccess = function(self, data)
		cb(data)
    end
	 
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.SaveQuestion(id,questions,enabled)
	local table = ""
	if questions then
		table = "`questions` = '"..questions.."'"
	end
	local enb = ""
	if enabled then
		enb = "`enabled` = '"..enabled.."'"
		if questions then questions = questions.."," end
	end
   local q = db:query("UPDATE `questions` SET "..table..enb.." WHERE `id`='"..id.."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.RemoveQuestion(id)
  local q = db:query("DELETE FROM `questions` WHERE `id`='"..id.."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.AddQuestion(name)
    local q = db:query("INSERT INTO `questions` (`name`,`questions`,`enabled`) VALUES ('"..db:escape(name).."','{}','0')")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.GetTests(sid,cb)
    local q = db:query("SELECT * FROM answers WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
    q.onSuccess = function(self, data)
		cb(data)
    end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end

	q:start()
end

function metadmin.AddTest(sid,ques,ans)
    local q = db:query("INSERT INTO `answers` (`sid`,`date`,`questions`,`answers`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..tonumber(ques).."','"..db:escape(ans).."')")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.SetStatusTest(id,status)
    local q = db:query("UPDATE `answers` SET `status` = '"..tonumber(status).."' WHERE `id`='"..tonumber(id).."'")
  q.onError = function(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Переподключение не удалось.")
            return
            end
        end
        MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function metadmin.GetViolations(sid,cb)
	local q = db:query("SELECT * FROM  `violations` WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function metadmin.AddViolation(sid,adminsid,violation)
	if not adminsid then adminsid = "CONSOLE" end
	local q = db:query("INSERT INTO `violations` (`SID`,`date`,`admin`,`server`,`violation`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..adminsid.."','"..db:escape(metadmin.server).."','"..db:escape(violation).."')")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function metadmin.RemoveViolation(id)
	local q = db:query("DELETE FROM `violations` WHERE `id`='"..id.."'")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end

function metadmin.GetExamInfo(sid,cb)
	local q = db:query("SELECT * FROM  `examinfo` WHERE SID='"..db:escape(sid).."' ORDER BY id DESC")
	q.onSuccess = function(self, data)
		cb(data)
	end
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end
function metadmin.AddExamInfo(sid,rank,adminsid,note,type)
	local q = db:query("INSERT INTO `examinfo` (`SID`,`date`,`rank`,`examiner`,`note`,`type`,`server`) VALUES ('"..db:escape(sid).."','"..os.time().."','"..rank.."','"..adminsid.."','"..db:escape(note).."','"..type.."','"..db:escape(metadmin.server).."')")
	q.onError = function(err, sql)
		if db:status() ~= mysqloo.DATABASE_CONNECTED then
			db:connect()
			db:wait()
			if db:status() ~= mysqloo.DATABASE_CONNECTED then
				ErrorNoHalt("Переподключение не удалось.")
				return
			end
		end
		MsgN('MySQL: Ошибка запроса: ' .. err .. ' (' .. sql .. ')')
		q:start()
	end
	q:start()
end