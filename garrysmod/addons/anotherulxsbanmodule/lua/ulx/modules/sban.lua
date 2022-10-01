--[[
--		Another ULX Source Bans Module 3.2
--
--		CREDITS:
--		This sban module was based on a very old version of ULX Source Bans Module by FunDK http://facepunch.com/showthread.php?t=1311847
--		It has been re-written a few times, but still has some bits of old stuff from the original.
-- 		The family sharing code is from McSimp on facepunch http://facepunch.com/showthread.php?t=1341204&p=43469693&viewfull=1#post43469693
--		The XGUI part of this module is the default ulx bans page modified to work with sbans. https://github.com/Nayruden/Ulysses/tree/master/ulx
--
--		INSTRUCTIONS:
--      Edit the config section below to your liking, make sure you add ulx_sban_serverid to your server.cfg
--		You can find the correct number to use from the sourcebans website, if you only have one server, it will usually be 1
--		There will be an additional permission you can assign in ulx called xgui_manageunbans, this will let your admins see the sourcebans tab.
--		The tab will currently only show ACTIVE bans.
--
--		Config files will be created after the first run at garrysmod/data/sban
--		Config settings in this file will be ignored once the config files have been created after the first run.
--]]
-- Config section
-- Add ulx_sban_serverid to your server.cfg
local SBAN_WEBSITE = "YourSite" --Source Bans Website
local SBAN_MODULE = "https://" .. SBAN_WEBSITE .. "/api/api.php"
local APIKey = "" -- See http://steamcommunity.com/dev/apikey
local APISban = ""
local removeFromGroup = true -- Remove users from server groups if they don't exist in the sourcebans database
local checkSharing = false -- Check if players are borrowing the game, !!!! THIS REQUIRES AN API KEY !!!!!
local checkIP = false -- Check ban database using IP.
local banLender = true -- Ban the lender of the game as well if the player gets banned?
local CommLender = true
local announceBanCount = true -- Announce to admins if players have bans on record.
local announceLender = true -- Announce to admins if players are borrowing gmod.
local banRetrieveLimit = 150 -- Amount of bans to retrieve in XGUI.
local banListRefreshTime = 119 -- Seconds between refreshing the banlist in XGUI, in case the bans change from outside of the server.
local tttKarmaBan = false -- Enable support for TTT karma bans.
ulxBanOverride = true -- Override the default ulx ban to use sban.

-- Table of groups who will get sharing/ban count notifications when players join.
-- Follow the format below to add more groups, make sure to add a comma if it isn't the last entry.
local adminTable = {
    ["superadmin"] = true,
    ["admin"] = true,
}

-- This table excludes named groups from being removed, even if the option is turned on.
-- Format is the same as the admin table above.
local excludedGroups = {}

local customAccess = {
    ["a"] = {['ulx reservedslots'] = true},
    ["b"] = {['ulx gag'] = true, ['ulx ungag'] = true, ['ulx mute'] = true, ['ulx unmute'] = true, ['ulx tsay'] = true, ['ulx demote'] = true, ['ulx undemote'] = true, ['ulx demoteid'] = true, ['ulx undemoteid'] = true, ['ulx jail'] = true, ['ulx unjail'] = true, ['awarn_view'] = true, ['awarn_warn'] = true, ['ulx cleanup'] = true, ['ulx banspray'] = true},
    ["c"] = {['ulx kick'] = true},
    ["d"] = {['ulx sban'] = true, ['ulx sbanid'] = true, ['ulx sgag'] = true, ['ulx smute'] = true , ['ulx unsmute'] = true, ['ulx unsgag'] = true},
    ["e"] = {['ulx unsbanid'] = true},
    ["f"] = {['ulx slay'] = true, ['ulx slap'] = true},
    ["g"] = {['ulx map'] = true, ['ulx votemap'] = true, ['ulx votemap2'] = true},
    --["h"] = {}, --["i"] = {},
    ["j"] = {['ulx seeanonymousechoes'] = true, ['ulx seeasay'] = true},
    ["k"] = {['ulx stopvote'] = true, ['ulx veto'] = true},
    --["l"] = {},
    ["m"] = {['ulx rcon'] = true, ['ulx luarun'] = true, ['ulx exec'] = true, ['ulx ent'] = true, ['ulx cexec'] = true},
    --["n"] = {}, --["o"] = {}, --["p"] = {}, --["q"] = {}, --["r"] = {},
    ["r"] = {['ulx send'] = true, ['ulx goto'] = true, ['ulx bring'] = true, ['ulx tp'] = true, ['ulx return'] = true},
    ["s"] = {['awarn_remove'] = true, ['awarn_delete'] = true, ['awarn_options'] = true, ['xgui_managedemotes'] = true, ['ulx editdemotesall'] = true, ['ulx undemoteall'] = true},
    ["t"] = {['ulx avoidness'] = true, ['ulx bhop'] = true, ['ulx change'] = true, ['ulx collision'] = true, ['ulx door'] = true, ['ulx flashlight'] = true, ['ulx forcespec'] = true, ['ulx freeday'] = true, ['ulx gagct'] = true, ['ulx gagsim'] = true, ['ulx gagt'] = true, ['ulx givewep'] = true, ['ulx guardbaninfo'] = true, ['ulx jails'] = true, ['ulx pickup'] = true, ['ulx propgmd'] = true, ['ulx respawn'] = true, ['ulx settime'] = true, ['ulx setcmd'] = true, ['ulx specday'] = true},
    ["z"] = {}
}

util.AddNetworkString( "sban_superadmin" )
if not file.Exists("sban", "DATA") then
    file.CreateDir("sban")
end

local configTable

if not file.Exists("sban/config.txt", "DATA") then
    configTable = {}
    configTable.SBAN_WEBSITE = SBAN_WEBSITE
    configTable.SBAN_MODULE = SBAN_MODULE
    configTable.APIKey = APIKey
    configTable.APISban = APISban
    configTable.removeFromGroup = removeFromGroup and "yes" or "no"
    configTable.checkSharing = checkSharing and "yes" or "no"
    configTable.checkIP = checkIP and "yes" or "no"
    configTable.banLender = banLender and "yes" or "no"
    configTable.commlender = CommLender and "yes" or "no"
    configTable.announceBanCount = announceBanCount and "yes" or "no"
    configTable.announceLender = announceLender and "yes" or "no"
    configTable.banRetrieveLimit = banRetrieveLimit
    configTable.banListRefreshTime = banListRefreshTime
    configTable.tttKarmaBan = tttKarmaBan and "yes" or "no"
    configTable.ulxBanOverride = ulxBanOverride and "yes" or "no"
    file.Write("sban/config.txt", util.TableToKeyValues(configTable))
else
    configTable = util.KeyValuesToTable(file.Read("sban/config.txt", "DATA"))
    SBAN_WEBSITE = configTable.sban_website
    SBAN_MODULE = configTable.sban_module
    APIKey = configTable.apikey
    APISban = configTable.apisban
    removeFromGroup = configTable.removefromgroup == "yes"
    checkSharing = configTable.checksharing == "yes"
    checkIP = configTable.checkIP and configTable.checkIP == "yes"
    banLender = configTable.banlender == "yes"
    CommLender = configTable.commlender == "yes"
    announceBanCount = configTable.announcebancount == "yes"
    announceLender = configTable.announcelender == "yes"
    banRetrieveLimit = tonumber(configTable.banretrievelimit)
    banListRefreshTime = tonumber(configTable.banlistrefreshtime)
    tttKarmaBan = configTable.tttkarmaban == "yes"
    ulxBanOverride = configTable.ulxbanoverride == "yes"
end

local function writeSAAccess()
    local function ulxValuesToKeys(t)
        local b = {}

        for k, v in pairs(t) do
            b[isnumber(k) and v or k] = true
        end

        return b
    end

    commands = {}
    access = ULib.ACCESS_SUPERADMIN

    while ULib.ucl.groups[access].inherit_from do
        local group = ULib.ucl.groups[access]
        local cmds = ulxValuesToKeys(group.allow)
        table.Merge(commands, cmds)
        access = group.inherit_from
    end

    return commands
end

if not file.Exists("sban/admingroups.json", "DATA") then
    file.Write("sban/admingroups.json", util.TableToJSON(adminTable))
else
    adminTable = util.JSONToTable(file.Read("sban/admingroups.json", "DATA"))
end

if not file.Exists("sban/excludedgroups.json", "DATA") then
    file.Write("sban/excludedgroups.json", util.TableToJSON(excludedGroups))
else
    excludedGroups = util.JSONToTable(file.Read("sban/excludedgroups.json", "DATA"))
end

if not file.Exists("sban/customaccess.json", "DATA") then
    customAccess['z'] = writeSAAccess()
    file.Write("sban/customaccess.json", util.TableToJSON(customAccess))
else
    customAccess = util.JSONToTable(file.Read("sban/customaccess.json", "DATA"))
end

CreateConVar("ulx_sban_serverid", "-1", FCVAR_NONE, "Setting the sban server number")
local apiErrorCount = 0
local apiLastCheck = 0
SBanTable = SBanTable or {}
local ipCache = {}

cvars.AddChangeCallback("ulx_sban_serverid", function()
    if GetConVar("ulx_sban_serverid"):GetInt() ~= -1 then
        SBAN_SERVERID = GetConVar("ulx_sban_serverid"):GetInt()
        print("[SB-API] [Init] ServerID: " .. SBAN_SERVERID)
    end
end)

hook.Add("Initialize", "checkServerID", function()
    if not SBAN_SERVERID then
        if not GetConVar("ulx_sban_serverid"):GetInt() then
            ErrorNoHalt("[SB-API] [ERROR] ulx_sban_serverid not set in server.cfg!\n")
        end

        SBAN_SERVERID = GetConVar("ulx_sban_serverid"):GetInt() or 1
    end
end)

local function SBAN_Msg(format, ...)
    local players = player.GetHumans()

    for i = #players, 1, -1 do
        local v = players[i]

        -- Calling player always gets to see the echo
        if not ULib.ucl.query(v, "ulx seeasay") then
            table.remove(players, i)
        end
    end

    ulx.fancyLog(players, "[#s]: " .. format, "SB-API", ...)
end

local function RemoveAdmin(ply)
    if (ULib.ucl.getUserRegisteredID(ply) ~= nil) and removeFromGroup and not excludedGroups[ply:GetUserGroup()] then
        ULib.ucl.removeUser(ply:SteamID())
        ply:SetPData("SBAN_FLAGS", "[]")
        SBAN_Msg("All privileges have been removed from #s!", ply:Nick())
        if ply.sb.sa then
            ply.sb.sa = false
            net.Start( "sban_superadmin")
                net.WriteBool(ply.sb.sa)
            net.Send(ply)
        end
    end
end

local function DoKick(ply, reason, length)
    local steamID

    if type(ply) == "string" then
        steamID = ply
    elseif IsValid(ply) and ply:IsPlayer() then
        steamID = ply:SteamID()
    else
        return
    end

    if reason == nil then
        game.KickID(steamID, "You have been banned for " .. (length == 0 and "lifetime" or "" .. ULib.secondsToStringTime(length, true)) .. ", please visit " .. SBAN_WEBSITE)
    else
        game.KickID(steamID, "You have been banned by '" .. reason .. "' for " .. (length == 0 and "lifetime" or "" .. ULib.secondsToStringTime(length, true)) .. ", please visit " .. SBAN_WEBSITE)
    end
end

local function DoMute(ply, admin, reason)
    if type(admin) == "string" then
        admin = admin
    elseif IsValid(admin) and admin:IsPlayer() then
        admin = admin:Nick()
    else
        admin = "Console"
    end

    local length = ply.sb.Muted - os.time()
    ULib.tsayColor(ply, true, Color(255, 146, 24), "Chat has been disabled by " .. admin .. " for " .. (ply.sb.Muted == 0 and "lifetime" or "" .. ULib.secondsToStringTime(length, true)) .. " by (" .. reason .. ").")
    ULib.tsayColor(ply, true, Color(246, 118, 142), "https://" .. SBAN_WEBSITE .. "/index.php?p=commslist&searchText=" .. ply:SteamID() .. "")

    hook.Add("PlayerSay", "sb_Muted", function(ply, text)
        if ply.sb.Muted and (ply.sb.Muted == 0 or ply.sb.Muted > os.time()) then return false end
    end)
end

local function DoGag(ply, admin, reason)
    if type(admin) == "string" then
        admin = admin
    elseif IsValid(admin) and admin:IsPlayer() then
        admin = admin:Nick()
    else
        admin = "Console"
    end

    local length = ply.sb.Gaged - os.time()
    ULib.tsayColor(ply, true, Color(255, 146, 24), "Your voice chat has been disabled by " .. admin .. " for " .. (ply.sb.Gaged == 0 and "lifetime" or "" .. ULib.secondsToStringTime(length, true)) .. " by (" .. reason .. ").")
    ULib.tsayColor(ply, true, Color(246, 118, 142), "https://" .. SBAN_WEBSITE .. "/index.php?p=commslist&searchText=" .. ply:SteamID() .. "")

    hook.Add("PlayerCanHearPlayersVoice", "sb_Gaged", function(listener, talker)
        if talker.sb.Gaged and (talker.sb.Gaged == 0 or talker.sb.Gaged > os.time()) then return false end
    end)
end

-------- API
local char_to_hex = function(c) return string.format("%%%02X", string.byte(c)) end

local function urlencode(url)
    if url == nil then return end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", char_to_hex)
    url = url:gsub(" ", "+")

    return url
end

local function ReqToServer(req, cb)
    local url = string.format("key=%s&sid=%s", APISban, SBAN_SERVERID)

    for k, v in pairs(req) do
        url = url .. string.format("&%s=%s", k, string.gsub(v, '[&=]', ''))
    end

    url = SBAN_MODULE .. '?' .. urlencode(url)

    http.Fetch(url, function(b, _, _, c)
        if c ~= 200 then
            SBAN_Msg("The request failed: #s", c)

            return
        end

        local t = util.JSONToTable(b)

        if not t.response.success then
            SBAN_Msg("Error: #s", t.response.def)

            return
        end

        cb(t.response.body)
    end, function(m)
        SBAN_Msg("The request failed: #s", m)
        print(m)

        return
    end)
end

local function ReportBlock(bid, name)
    local req = {
        ["op"] = "banlog",
        ["bid"] = bid,
        ["name"] = name,
        ["time"] = os.time()
    }

    ReqToServer(req, function() end)
end

local function SBAN_Ban(ip, steamID, name, length, reason, adminID, cb)
    local req = {
        ["op"] = "newban",
        ["ip"] = ip,
        ["id"] = steamID,
        ["name"] = name,
        ["time"] = os.time(),
        ["length"] = length,
        ["reason"] = reason,
        ["aid"] = adminID
    }

    ReqToServer(req, function(res)
        cb(res)

        if res.added then
            SBAN_RetrieveBans()
        end
    end)
end

local function SBAN_Comm(steamID, name, length, reason, adminID, type, cb)
    local req = {
        ["op"] = "newcomm",
        ["id"] = steamID,
        ["name"] = name,
        ["time"] = os.time(),
        ["length"] = length,
        ["reason"] = reason,
        ["aid"] = adminID,
        ["type"] = type
    }

    ReqToServer(req, cb)
end

local function SBAN_Uncomm(steamID, adminID, reason, type, cb)
    local req = {
        ["op"] = "uncomm",
        ["id"] = steamID,
        ["aid"] = adminID,
        ["time"] = os.time(),
        ["type"] = type,
        ["reason"] = reason
    }

    ReqToServer(req, cb)
end

local function ModifyPermissons(steamID, ply, perm)
    local tb1 = util.JSONToTable(ply:GetPData("SBAN_FLAGS", "{}")) or {}
    if not perm.access and table.Count(tb1) == 0 then return end
    local web = perm.flags or {}

    if web['z'] then
        web = {
            ['z'] = true
        }
    end

    local grant = {}
    local revoke = {}

    if not web['z'] then
        for k, v in pairs(customAccess) do
            if not tb1[k] and web[k] then
                table.Merge(grant, v)
            elseif tb1[k] and not web[k] then
                table.Merge(revoke, v)
            end
        end
    else
        if not tb1['z'] then
            grant = customAccess['z']
            ply.sb.sa = true
        end
    end

    if tb1['z'] and not web['z'] then
        for k, _ in pairs(grant) do
            revoke[k] = nil
        end

        ply.sb.sa = false

        grant = {}
    end

    if table.Count(grant) > 0 then
        grant = table.GetKeys( grant )
        ULib.ucl.userAllow(steamID, grant)
        local msg = string.format("[SB-API] %s (%s) access granted to <%s>", ply:Nick(), ply:SteamID(), table.concat(grant, ", "))
        ulx.logString(msg, false)
        SBAN_Msg("Player #s (#s) has the following rights: <#s>", ply:Nick(), steamID, web['z'] and 'superadmin' or table.concat(grant, ", "))
    end

    if table.Count(revoke) > 0 then
        revoke = table.GetKeys( revoke )
        ULib.ucl.userAllow(steamID, revoke, true, false)
        local msg = string.format("[SB-API] %s (%s) access revoked from <%s>", ply:Nick(), ply:SteamID(), table.concat(revoke, ", "))
        ulx.logString(msg, false)
        SBAN_Msg("Player #s (#s) has their rights revoked: <#s>", ply:Nick(), steamID, (not web['z'] and tb1['z']) and 'superadmin' or table.concat(revoke, ", "))
    end

    ply:SetPData("SBAN_FLAGS", util.TableToJSON(web))

    net.Start( "sban_superadmin")
        net.WriteBool(ply.sb.sa)
    net.Send(ply)
end

local function CheckAdmin(steamID, ply)
    local req = {
        ["op"] = "getadmin",
        ["id"] = steamID
    }

    ReqToServer(req, function(res)
        if not res.isAdmin then
            RemoveAdmin(ply)

            return
        end

        ply.sb.aid = res.aid
        ply.sb.password = not res.password and not res.password or res.password
        ply.sb.immunity = res.immunity
        local cp = {}

        --CustomFlags
        if res.permissions.access then
            if not res.permissions.flags['z'] then
                for k, _ in pairs(res.permissions.flags) do
                    table.Add(cp, customAccess[k])
                end
            else
                cp = customAccess['z']
            end
        end

        if res.group ~= nil and string.len(res.group) > 0 then
            if ULib.ucl.getUserRegisteredID(ply) == nil or ply:GetUserGroup() ~= res.group then
                ULib.ucl.addUser(steamID, cp, {}, res.group)
                ply:SetPData("SBAN_FLAGS", util.TableToJSON(res.permissions.flags or {}))
                SBAN_Msg("Player #s is given group '#s'!", ply:Nick(), ply:GetUserGroup())
                if res.permissions.access then
                    SBAN_Msg("Player #s (#s) has the following rights: <#s>", ply:Nick(), steamID, res.permissions.flags['z'] and 'superadmin' or table.concat(cp, ", "))
                    ulx.logString(string.format("[SB-API] The player %s (%s) has been given permissions to: <%s>", ply:Nick(), steamID, table.concat(cp, ", ")), true)
                end
                return
            end

            return ModifyPermissons(steamID, ply, res.permissions)
        else
            RemoveAdmin(ply)

            return ModifyPermissons(steamID, ply, res.permissions)
        end
    end)
end

function SBAN_Auth(ply, pass)
    if not ply:IsValid() then return false, 4 end
    if not ply.sb.aid then return false, 1 end
    if ply.sb.password == true then return false, 2 end
    if ply.sb.password == util.SHA256(pass) then return true end

    return false, 3
end

------- API
local function StillBanned(ply, bid, reason, preSpawn, length)
    if not preSpawn and not IsValid(ply) then return end
    local name
    local steamID

    if preSpawn then
        name = ply.name
        steamID = ply.steamID
    else
        name = ply:Nick()
        steamID = ply:SteamID()
    end

    ReportBlock(bid, name)
    DoKick(steamID, reason, length)
end

local function StillComm(ply, ends, length, reason, admin, comms_type)
    if not IsValid(ply) then return end

    if length == 0 then
        ends = 0
    end

    if comms_type == 2 then
        ply.sb.Muted = ends
        DoMute(ply, admin, reason)
    end

    if comms_type == 1 then
        ply.sb.Gaged = ends
        DoGag(ply, admin, reason)
    end
end

ULib.ucl.registerAccess("ulx unsbanall", ULib.ACCESS_SUPERADMIN, "Ability to unban all sban entries", "Other") -- Permission for admins to unban players banned by other admins.
ULib.ucl.registerAccess("ulx editsbanall", ULib.ACCESS_SUPERADMIN, "Ability to edit all sban entries", "Other") -- Permission for admins to edit bans made by other admins.

function SBAN_dobanID(inip, steamID, name, length, reason, callingAdmin, cb)
    local adminID = callingAdmin.sb and (callingAdmin.sb.aid or 0) or 0
    local ip = string.Explode(":", inip)[1]

    return SBAN_Ban(ip, steamID, name, length, reason, adminID, cb)
end

function SBAN_doban(inip, steamID, name, length, reason, callingAdmin, lenderID, cb)
    local adminID = callingAdmin.sb and (callingAdmin.sb.aid or 0) or 0
    local ip = string.Explode(":", inip)[1]
    SBAN_Ban(ip, steamID, name, length, reason, adminID, cb)

    if lenderID and banLender then
        SBAN_Ban(ip, lenderID, name, length, reason, adminID, cb)
    end
end

function SBAN_docomm(steamid, name, length, reason, callingAdmin, lenderID, comms_type, cb)
    local adminID = callingAdmin.sb and (callingAdmin.sb.aid or 0) or 0
    SBAN_Comm(steamid, name, length, reason, adminID, comms_type, cb)

    if lenderID and CommLender then
        SBAN_Comm(lenderID, name, length, reason, adminID, comms_type, cb)
    end
end

function SBAN_banplayer(ply, length, reason, callingadmin, cb)
    local lenderid = nil

    if ply.sb.familyshared then
        lenderid = ply.sb.lenderid
    end

    local ip = string.Explode(":", ply:IPAddress())[1]
    local steamID = ply:SteamID()
    local name = ply:Nick()
    SBAN_doban(ip, steamID, name, length, reason, callingadmin, lenderid, cb)
    DoKick(steamID, reason, length)
end

function SBAN_uncommsplayer(ply, ureason, callingadmin, comms_type, cb)
    local adminID = callingadmin.sb and (callingadmin.sb.aid or 0) or 0
    local steamID = ply:SteamID()
    local access = tostring(ULib.ucl.query(callingadmin, "ulx unsbanall"))

    local req = {
        ["op"] = "canuncomm",
        ["id"] = steamID,
        ["aid"] = adminID,
        ["type"] = comms_type,
        ["unall"] = access
    }

    ReqToServer(req, function(res)
        if not res.can then
            cb(res)

            return
        end

        SBAN_Uncomm(steamID, adminID, ureason, comms_type, cb)
    end)
end

function SBAN_commsplayer(ply, length, reason, callingadmin, comms_type, cb)
    local steamid = ply:SteamID()
    local name = ply:Nick()
    local lenderid = nil

    if ply.sb.familyshared then
        lenderid = ply.sb.lenderid
    end

    if comms_type == 2 then
        ply.sb.Muted = length ~= 0 and length + os.time() or 0
        DoMute(ply, callingadmin, reason)
    elseif comms_type == 1 then
        ply.sb.Gaged = length ~= 0 and length + os.time() or 0
        DoGag(ply, callingadmin, reason)
    end

    SBAN_docomm(steamid, name, length, reason, callingadmin, lenderid, comms_type, cb)
end

function SBAN_unban(steamid, ply, ureason, cb)
    local adminID = ply.sb and (ply.sb.aid or 0) or 0

    local req = {
        ["op"] = "unban",
        ["id"] = steamid,
        ["aid"] = adminID,
        ["time"] = os.time(),
        ["reason"] = ureason
    }

    ReqToServer(req, function(res)
        XGUIRefreshBans()
        cb(res)
    end)
end

function SBAN_canunban(steamid, ply, cb)
    local adminID = ply.sb and (ply.sb.aid or 0) or 0
    local access = tostring(ULib.ucl.query(ply, "ulx unsbanall"))

    local req = {
        ["op"] = "canunban",
        ["id"] = steamid,
        ["aid"] = adminID,
        ["unall"] = access
    }

    ReqToServer(req, cb)
end

function SBAN_updateban(steamID, ply, bantime, reason, name, cb)
    local updateName = "[Unknown]"

    if name and string.len(name) > 0 then
        updateName = name
    end

    local req = {
        ["op"] = "updateban",
        ["id"] = steamid,
        ["length"] = bantime,
        ["name"] = updateName,
        ["reason"] = reason
    }

    ReqToServer(req, function(res)
        XGUIRefreshBans()
        cb(res)
    end)
end

local function UpdateBanList(result)
    local tempTable = {}

    for k, v in pairs(result) do
        tempTable[v.authid] = {}
        tempTable[v.authid].bid = v.bid
        tempTable[v.authid].sid = tonumber(v.sid) > 0 and v.sid or "Web"
        tempTable[v.authid].admin = v.admin
        tempTable[v.authid].adminid = v.aid
        tempTable[v.authid].name = v.name
        tempTable[v.authid].reason = v.reason
        tempTable[v.authid].steamID = v.authid
        tempTable[v.authid].time = v.created
        tempTable[v.authid].unban = v.created == v.ends and 0 or v.ends
    end

    SBanTable = tempTable
end

function SBAN_RetrieveBans()
    if not banRetrieveLimit or type(banRetrieveLimit) ~= number then
        banRetrieveLimit = 150
    end

    local req = {
        ["op"] = "retrievebans",
        ["limit"] = banRetrieveLimit
    }

    ReqToServer(req, function(res)
        UpdateBanList(res.res)
    end)
end

hook.Add("InitPostEntity", "LoadSbans", function()
    timer.Simple(1, SBAN_RetrieveBans)
end)

timer.Create("UpdateBanListPls", banListRefreshTime, 0, SBAN_RetrieveBans)

local function StartAdminCheck(ply, steamid)
    CheckAdmin(steamid, ply)
end

local function DetermineUniv(result, data, preSpawn)
    local ply
    local steamid

    if preSpawn then
        ply = {}
        ply.name = data.name
        ply.steamID = data.steamID
    else
        ply = data.ply
        steamid = data.steamID
    end

    if result.ban then
        StillBanned(ply, result.res.bid, result.res.reason, preSpawn, tonumber(result.res.length))
    end

    if preSpawn then return end

    if announceBanCount then
        local function cb(r)
            local count = table.Count(r.res)
            if count == 0 then return end

            timer.Simple(10, function()
                if not ply:IsValid() then return end
                local plural = count > 1 and "times" or "time"
                local str = ply.sb.familyshared and "Player #s - (#s) was banned #s #s!" or "Player #s (#s) was banned #s #s!"
                SBAN_Msg(str, ply:Nick(), steamid, count, plural)
            end)
        end

        local req = {
            ["op"] = "bans",
            ["id"] = steamid
        }

        ReqToServer(req, cb)
    end

    if result.comms then
        for _, v in pairs(result.res) do
            StillComm(ply, tonumber(v.ends), tonumber(v.length), v.reason, v.user, tonumber(v.type))
        end
    end

    if ply.sb.familyshared then return end
    StartAdminCheck(ply, steamid)
end

local function StartUnivCheck(ply, steamID)
    local data = {}
    data.ply = ply
    data.steamID = steamID

    local req = {
        ["op"] = "getblocks",
        ["id"] = steamID
    }

    ReqToServer(req, function(res)
        DetermineUniv(res, data)
    end)
end

local function AnnounceLender(ply, lender)
    if not IsValid(ply) or not announceLender then return end

    timer.Create("FSAnnounce" .. ply:SteamID(), 10, 1, function()
        if not IsValid(ply) then return end
        SBAN_Msg("[#s] #s (#s) took Garry's Mod from #s!", "Family Sharing", ply:Nick(), ply:SteamID(), lender)
    end)
end

local function HandleSharedPlayer(ply, lenderSteamID)
    apiErrorCount = (apiErrorCount > 1) and (apiErrorCount - 1) or 0
    if not IsValid(ply) then return end
    AnnounceLender(ply, lenderSteamID)
    ply.sb.familyshared = true
    ply.sb.lenderid = lenderSteamID
    StartUnivCheck(ply, lenderSteamID)
end

local function CheckFamilySharing(ply)
    apiLastCheck = apiLastCheck or 0
    if not IsValid(ply) or apiErrorCount > 100 then return end

    if (CurTime() - apiLastCheck <= 1) or CurTime() < 12 then
        local checkDelay = math.Rand(2, 25)

        timer.Create("FSCheck_" .. ply:SteamID(), checkDelay, 1, function()
            if not IsValid(ply) then return end
            CheckFamilySharing(ply)
        end)

        return
    end

    apiLastCheck = CurTime()

    http.Fetch(string.format("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=%s&format=json&steamid=%s&appid_playing=4000", APIKey, ply:SteamID64()), function(body)
        if not IsValid(ply) then return end
        body = util.JSONToTable(body)

        if not body or not body.response or not body.response.lender_steamid then
            ErrorNoHalt(string.format("[SBAN] FamilySharing: Invalid Steam API for %s | %s\n", ply:Nick(), ply:SteamID()))
            apiErrorCount = apiErrorCount + 2
            CheckFamilySharing(ply)

            return
        end

        local lender = body.response.lender_steamid

        if lender ~= "0" then
            if not IsValid(ply) then return end
            local lenderSteamID = util.SteamIDFrom64(lender)
            HandleSharedPlayer(ply, lenderSteamID)
        end
    end, function(code)
        if not IsValid(ply) then return end
        ErrorNoHalt(string.format("[SBAN] FamilySharing: Failed API request %s | %s (Error: %s)\n", ply:Nick(), ply:SteamID(), code))
        apiErrorCount = apiErrorCount + 2
        CheckFamilySharing(ply)
    end)
end

local function SBAN_rehash(ply, cmd, args, str)
    if IsValid(ply) then return end

    for k, v in pairs(player.GetAll()) do
        StartAdminCheck(v, v:SteamID())
    end
end

concommand.Add("sm_rehash", SBAN_rehash)
concommand.Add("sban_rehash", SBAN_rehash)

concommand.Add("sm_psay", function(_, _, args)
    local name = args[1]
    local msg = args[2]

    for _, v in pairs(player.GetHumans()) do
        if v:Nick() == name then
            ulx.psay(Player(0), v, msg)

            return
        end
    end
end)

local function SBAN_serverid_cmd(ply, cmd, args, str)
    if IsValid(ply) then return end
    print("[SBAN] ServerID: " .. SBAN_SERVERID)
end

concommand.Add("sban_serverid", SBAN_serverid_cmd)

local function SBAN_playerconnect(ply, steamID)
    ply.sb = {}
    ply.sb.sa = util.JSONToTable(ply:GetPData("SBAN_FLAGS", "{}")).z or false

    StartUnivCheck(ply, steamID)

    if checkSharing then
        CheckFamilySharing(ply)
    end
end

local function PW_BanCheck(sid64, ip, svPass, clPass, name)
    local data = {}
    data.name = name
    data.steamID = util.SteamIDFrom64(sid64)
    data.ip = string.Explode(":", ip)[1]

    local req = {
        ["op"] = "getblocks",
        ["id"] = data.steamID
    }

    ReqToServer(req, function(res)
        DetermineUniv(res, data, true)
    end)

    if checkIP then
        local req = {
            ["op"] = "getblocks",
            ["ip"] = data.ip
        }

        ReqToServer(req, function(res)
            DetermineUniv(res, data, true)
        end)

        ipCache[data.ip] = true
    end
end

hook.Add("PlayerAuthed", "sban_ulx", SBAN_playerconnect)
hook.Add("CheckPassword", "sban_ulx_checkpassword", PW_BanCheck)

hook.Add("TTTKarmaLow", "KarmaSourceBan", function(ply)
    if tttKarmaBan and KARMA and KARMA.cv.enabled:GetBool() and KARMA.cv.autoban:GetBool() then
        SBAN_doban(ply:IPAddress(), ply:SteamID(), ply:Nick(), KARMA.cv.bantime:GetInt() * 60, "Karma too low", 0, ply.sb.lenderid)
    end
end)