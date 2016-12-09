AddCSLuaFile()
metadmin = metadmin or {}
metadmin.category = "MetAdmin" -- Категория в ulx
if (SERVER) then
	AddCSLuaFile("metadmin/client.lua")
	
	include("metadmin/sha256.lua")
	include("metadmin/server.lua")
else
	include("metadmin/client.lua")
end