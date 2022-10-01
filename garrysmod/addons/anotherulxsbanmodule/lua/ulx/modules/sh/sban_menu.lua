local CATEGORY_NAME = "Source Bans"

function ulx.sban( calling_ply, target_ply, minutes, reason )
	
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Нельзя банить бота", true )
		return
	end
	
	if !reason or string.len(reason) < 3 or reason == "reason" then
	ULib.tsayError( calling_ply, "Ошибка: Укажите причину бана!", true )
	return
	end
	
	local time = "for #i minute(s)"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason )
	
	ULib.queueFunctionCall( SBAN_banplayer, target_ply, minutes*60, reason, calling_ply)
end
local sban = ulx.command( CATEGORY_NAME, "ulx sban", ulx.sban, "!sban" )
sban:addParam{ type=ULib.cmds.PlayerArg }
sban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
sban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
sban:defaultAccess( ULib.ACCESS_ADMIN )
sban:help( "Bans target." )
-- Comms --
function ulx.smute( calling_ply, target_ply, minutes, reason, should_unmute )
	
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Боту нельзя отключить чат", true )
		return
	end

	if should_unmute then
			if target_ply.sb_Muted == nil then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " не в муте!", true )
			return
			end
			
			if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Ошибка: Укажите причину снятия мута!", true )
			return
			end
			
			SBAN_uncommsplayer(target_ply, reason, calling_ply, 2)	
		else
			if (target_ply.sb_Muted ~=nil and (target_ply.sb_Muted>os.time() or target_ply.sb_Muted == 0)) then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " в муте!", true )
			return
			end
			
			if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Ошибка: Укажите причину мута!", true )
			return
			end
			
				if (SBAN_commsplayer(target_ply, minutes*60, reason, calling_ply, 2)) then
				local time = "for #i minute(s)"
				if minutes == 0 then time = "permanently" end
				local str = "#A muted #T " .. time
				if reason and reason ~= "" then str = str .. " (#s)" end
				ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason )
			end
	end
		
end
local smute = ulx.command( CATEGORY_NAME, "ulx smute", ulx.smute, "!smute" )
smute:addParam{ type=ULib.cmds.PlayerArg }
smute:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
smute:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_comms_reasons }
smute:addParam{ type=ULib.cmds.BoolArg, invisible=true }
smute:defaultAccess( ULib.ACCESS_ADMIN )
smute:help( "Отключить текстовой чат игроку." )
smute:setOpposite( "ulx unsmute", {_, _, 0, _, true}, "!unsmute" )

function ulx.sgag( calling_ply, target_ply, minutes, reason, should_ungag )
	
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Cannot gag a bot", true )
		return
	end
	
	if should_ungag then
			if target_ply.sb_Gaged == nil then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " не в гаге!", true )
			return
			end
			
			if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Ошибка: Укажите причину снятия гага!", true )
			return
			end
			
			SBAN_uncommsplayer(target_ply, reason, calling_ply, 1)
		else
			if (target_ply.sb_Gaged ~=nil and(target_ply.sb_Gaged>os.time() or target_ply.sb_Gaged == 0)) then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " в гаге!", true )
			return
			end
			
			if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Ошибка: Укажите причину гага!", true )
			return
			end
			
				if(SBAN_commsplayer(target_ply, minutes*60, reason, calling_ply, 1)) then
						local time = "for #i minute(s)"
						if minutes == 0 then time = "permanently" end
						local str = "#A gaged #T " .. time
						if reason and reason ~= "" then str = str .. " (#s)" end
						ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason )
				end
	end

end
local sgag = ulx.command( CATEGORY_NAME, "ulx sgag", ulx.sgag, "!sgag" )
sgag:addParam{ type=ULib.cmds.PlayerArg }
sgag:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
sgag:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_comms_reasons }
sgag:addParam{ type=ULib.cmds.BoolArg, invisible=true }
sgag:defaultAccess( ULib.ACCESS_ADMIN )
sgag:help( "Gags target." )
sgag:setOpposite( "ulx unsgag", {_, _, 0, _, true}, "!unsgag" )

-- Comms --
function ulx.sbanid( calling_ply, steamid, minutes, reason, should_unbanid )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Неверный SteamID." )
		return
	end
	if should_unbanid then
		if SBanTable[ steamid ] then
		if ( SBanTable[ steamid ].adminid != calling_ply.sb_aid ) and !ULib.ucl.query( calling_ply, "ulx unsbanall" )  then
			ULib.tsayError( calling_ply, "Ошибка: У вас нет прав на удаление бана другого админа.", true )
			return
		end
		local function cb()
		name = SBanTable[ steamid ] and SBanTable[ steamid ].name
		if name == nil then return end
		if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Ошибка: Укажите причину снятия бана!", true )
			return
		end
		SBAN_unban( steamid, calling_ply, reason )
		if name then
			ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid .. " (" .. name .. ")" )
		else
			ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid )
		end
	end
	if not SBanTable[ steamid ] then
		SBAN_canunban(steamid, calling_ply, function(result,qtab)
			if #result > 0 then
				ULib.tsayError( calling_ply, "Ошибка: У вас нет прав на удаление бана другого админа.", true )
			else
				cb()
			end
		end)
	else
		cb()
	end
	end
	else
	if !reason or string.len(reason) < 3 or reason == "reason" then
	ULib.tsayError( calling_ply, "Ошибка: Укажите причину бана!", true )
	return
	end
	local name
	local targetPly = player.GetBySteamID(steamid)
	name = targetPly and targetPly:Nick() or nil
	SBAN_dobanID((targetPly and targetPly:IPAddress() or "unknown"), steamid, (name and name or "[Unknown]"), minutes*60, reason, calling_ply)
	if targetPly then
		timer.Simple(0, function()
			if !IsValid(targetPly) then return end
			targetPly:Kick(reason)
		end)
	end
	end
end
local sbanid = ulx.command( CATEGORY_NAME, "ulx sbanid", ulx.sbanid )
sbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
sbanid:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
sbanid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
sbanid:addParam{ type=ULib.cmds.BoolArg, invisible=true }
sbanid:defaultAccess( ULib.ACCESS_SUPERADMIN )
sbanid:help( "Бан по SteamID." )
sbanid:setOpposite( "ulx unsbanid", {_, _, 0, _, true}, "!unsbanid" )

------------------------------ Vote SBan ------------------------------

local function voteSBanDone2( t, target, time, ply, reason )
	local shouldBan = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logUserAct( ply, target, "#A approved the votesban against #T (" .. time .. " minutes) (" .. (reason or "") .. ")" )
		shouldBan = true
	else
		ulx.logUserAct( ply, target, "#A denied the votesban against #T" )
	end

	if shouldBan then
		
	local banTimeWords = "for #i minute(s)"
	if time == 0 then banTimeWords = "permanently" end
	local str = "#A banned #T " .. banTimeWords
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( ply, str, target, time ~= 0 and time or reason, reason )
	
	reason = reason .. " by ["..ply:SteamID().."]"
	
	ULib.queueFunctionCall( SBAN_banplayer, target, time*60, reason, 1)
	end
end

local function voteSBanDone( t, target, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votesbanSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votesbanMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be banned. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		str = "Vote results: User will now be banned for " .. time .. " minutes, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
		ulx.doVote( "Accept result and ban " .. target:Nick() .. "?", { "Yes", "No" }, voteSBanDone2, 30000, { ply }, true, target, time, ply, reason )
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.voteSBan( calling_ply, target_ply, minutes, reason )
	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end
	
	if !reason or string.len(reason) < 3 or reason == "reason" then
	ULib.tsayError( calling_ply, "Ошибка: Укажите причину бана!", true )
	return
	end
	
	local msg = "SBan " .. target_ply:Nick() .. " for " .. minutes .. " minutes?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "Yes", "No" }, voteSBanDone, _, _, _, target_ply, minutes, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A started a votesban of #i minute(s) against #T (#s)", minutes, target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A started a votesban of #i minute(s) against #T", minutes, target_ply )
	end
end
local votesban = ulx.command( CATEGORY_NAME, "ulx votesban", ulx.voteSBan, "!votesban" )
votesban:addParam{ type=ULib.cmds.PlayerArg }
votesban:addParam{ type=ULib.cmds.NumArg, min=0, default=1440, hint="minutes", ULib.cmds.allowTimeString, ULib.cmds.optional }
votesban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
votesban:defaultAccess( ULib.ACCESS_ADMIN )
votesban:help( "Starts a public SourceBan vote against target player." )
if SERVER then ulx.convar( "votesbanSuccessratio", "0.7", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votesban to succeed
if SERVER then ulx.convar( "votesbanMinvotes", "3", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votesban

if ulxBanOverride then
	timer.Simple(0, function()
	
		local sbanov = ulx.command( "Utility", "ulx ban", ulx.sban, "!ban" )
		sbanov:addParam{ type=ULib.cmds.PlayerArg }
		sbanov:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
		sbanov:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
		sbanov:defaultAccess( ULib.ACCESS_ADMIN )
		sbanov:help( "Bans target." )
		
		local sbanidov = ulx.command( "Utility", "ulx banid", ulx.sbanid )
		sbanidov:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
		sbanidov:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
		sbanidov:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
		sbanidov:defaultAccess( ULib.ACCESS_SUPERADMIN )
		sbanidov:help( "Bans steamid." )
	end)
end