local CATEGORY_NAME = "Source Bans"

function ulx.sbauth( calling_ply, password )
	
	if !calling_ply:IsValid() then
		ULib.tsayError( calling_ply, "Error, u not valid player!", true )
		return 
	end

	local success, code = SBAN_Auth(calling_ply, password)
	
	if success then
		calling_ply.sb.password = true
		ULib.tsayError( calling_ply, "Successful auth!", true )
	else
		local str

		if code == 1 then
			str = "Error, you are not an administrator or no data has been received!"
		elseif code == 2 then
			str = "Error, authorization has already been completed or the password has not been set!"
		else
			str = "Error, password entered incorrectly!"
		end

		ULib.tsayError( calling_ply, str, true )
	end
end
local sbauth = ulx.command( CATEGORY_NAME, "ulx sbauth", ulx.sbauth )
sbauth:addParam{ type=ULib.cmds.StringArg, hint="Your sv password", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
sbauth:defaultAccess( ULib.ACCESS_SUPERADMIN )
sbauth:help( "SBAN account authorization, allows you to execute ULX commands. If there is a server password in SBAN." )

function ulx.sban( calling_ply, target_ply, minutes, reason )
	
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Cannot ban a bot", true )
		return
	end

	if !reason or string.len(reason) < 3 or reason == "reason" then
		ULib.tsayError( calling_ply, "Error: Specify the reason for the ban!", true )
		return
	end
	
	local target = target_ply:Nick()

	local function cb(r)
		if !r.added then
			if r.reason == 'alreadybanned' then ULib.tsayError( calling_ply, "Error: This player is already banned!", true ) return end
			ULib.tsayError( calling_ply, "Error: Unknown error!", true )
			return
		else
			local time = minutes!=0 and ULib.secondsToStringTime(minutes*60,true) or "permanently"
			local str = "#A banned steamid (#s) "..(minutes!=0 and"for "or"").."#s"..((reason and reason ~= "") and " (#s)" or "")
			ulx.fancyLogAdmin( calling_ply, str, target, time, reason )
		end
	end
	ULib.queueFunctionCall( SBAN_banplayer, target_ply, minutes*60, reason, calling_ply, cb)
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
		ULib.tsayError( calling_ply, "Cannot mute a bot", true )
		return
	end

	if should_unmute then
		if target_ply.sb.Muted == nil then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " not in mute!", true )
			return
		end

		if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Error: Specify the reason of unsmute!", true )
			return
		end

		local function cb(r)
			if !r.can and !r.uncommed then ULib.tsayError( calling_ply, r.reason == 'notcommed' and "Error: This player is not muted!" or "Error: You don't have enough access to unsmute!", true ) return end

			if r.uncommed then
			    target_ply.sb.Muted = nil
			    ulx.fancyLogAdmin( calling_ply, "#A unmuted #T"..(reason and reason ~= "") and " (#s)" or "", target_ply, reason )
			end
		end

		ULib.queueFunctionCall( SBAN_uncommsplayer, target_ply, reason, calling_ply, 2, cb)
	else

		if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Error: Specify the reason of smute!", true )
			return
		end

		local function cb(r)
			if !r.added then
				ULib.tsayError( calling_ply, r.reason == 'alreadyblocked' and target_ply:Nick() .. " already muted!" or 'Erorr: Unknown error', true )
				return
			else
				local time = minutes!=0 and ULib.secondsToStringTime(minutes*60,true) or "permanently"
				local str = "#A muted #T "..(minutes!=0 and"for "or"").."#s"..((reason and reason ~= "") and " (#s)" or "")

				ulx.fancyLogAdmin( calling_ply, str, target_ply, time, reason )
			end
		end
			
		ULib.queueFunctionCall( SBAN_commsplayer, target_ply, minutes*60, reason, calling_ply, 2, cb)
	end

end

local smute = ulx.command( CATEGORY_NAME, "ulx smute", ulx.smute, "!smute" )
smute:addParam{ type=ULib.cmds.PlayerArg }
smute:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
smute:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_comms_reasons }
smute:addParam{ type=ULib.cmds.BoolArg, invisible=true }
smute:defaultAccess( ULib.ACCESS_ADMIN )
smute:help( "Mute target." )
smute:setOpposite( "ulx unsmute", {_, _, 0, _, true}, "!unsmute" )

function ulx.sgag( calling_ply, target_ply, minutes, reason, should_ungag )

	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Cannot gag a bot", true )
		return
	end

	if should_ungag then

		if target_ply.sb.Gaged == nil then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " not gaged!", true )
			return
		end

		if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Error: Specify the reason of unsgag!", true )
			return
		end

		local function cb(r)
			if !r.can and !r.uncommed then ULib.tsayError( calling_ply, r.reason == 'notcommed' and "Error: This player is not gaged!" or "Error: You don't have enough access to unsgag!", true ) return end

			if r.uncommed then
				local str = "#A ungaged #T "..((reason and reason ~= "") and " (#s)" or "")
					
				ulx.fancyLogAdmin( calling_ply, str, target_ply, reason )
			end
		end

		ULib.queueFunctionCall( SBAN_uncommsplayer, target_ply, reason, calling_ply, 1, cb)
	else

		if !reason or string.len(reason) < 3 or reason == "reason" then
			ULib.tsayError( calling_ply, "Error: Specify the reason of sgag!", true )
			return
		end

		local function cb(r)
			if !r.added then
				ULib.tsayError( calling_ply, r.reason == 'alreadyblocked' and target_ply:Nick() .. " already gaged!" or 'Error: Unknown error', true )
				return
			else
				local time = minutes!=0 and ULib.secondsToStringTime(minutes*60,true) or "permanently"
				local str = "#A gaged #T "..(minutes!=0 and"for "or"").."#s"..((reason and reason ~= "") and " (#s)" or "")
					
				ulx.fancyLogAdmin( calling_ply, str, target_ply, time, reason )
			end
		end

		ULib.queueFunctionCall( SBAN_commsplayer, target_ply, minutes*60, reason, calling_ply, 1, cb)
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
		ULib.tsayError( calling_ply, "Invalid SteamID." )
		return
	end
	
	if should_unbanid then
		if SBanTable[ steamid ] then
			if ( SBanTable[ steamid ].adminid != calling_ply.sb.aid ) and !ULib.ucl.query( calling_ply, "ulx unsbanall" )  then
				ULib.tsayError( calling_ply, "Error: You do not have access to remove the ban of another admin.", true )
				return
			end

			local function cb()
				name = SBanTable[ steamid ] and SBanTable[ steamid ].name
				if name == nil then return end
				if !reason or string.len(reason) < 3 or reason == "reason" then
					ULib.tsayError( calling_ply, "Error: Specify the reason of unsbanid!", true )
					return
				end

				ULib.queueFunctionCall( SBAN_unban, steamid, calling_ply, reason, function(r)
					if r.unbanned then
						if name then
							ulx.fancyLogAdmin( calling_ply, "#A unbanned #s (#s)", steamid, name)
						else
							ulx.fancyLogAdmin( calling_ply, "#A unbanned #s", steamid )
						end
					else
						ULib.tsayError( calling_ply, "Error: Unknown error.", true )
					end
				end)
			end

			if not SBanTable[ steamid ] then
				ULib.queueFunctionCall(SBAN_canunban, steamid, calling_ply, function(result)
					if !result.can then
						ULib.tsayError( calling_ply, "Error: You do not have access to remove the ban of another admin.", true )
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
			ULib.tsayError( calling_ply, "Error: Specify the reason for the ban!", true )
			return
		end

		local targetPly = player.GetBySteamID(steamid)
		local name = targetPly and targetPly:Nick() or nil
		
		local function cb(r)
			if !r.added then
				ULib.tsayError( calling_ply, r.reason == 'alreadybanned' and "Error: This player has already been banned." or "Error: Unknown error.", true )
				return
			else
				local time = minutes!=0 and ULib.secondsToStringTime(minutes*60, true) or "permanently"
                local str = "#A banned #s "..(minutes!=0 and"for "or"").."#s"..((reason and reason ~= "") and " (#s)" or "")
                ulx.fancyLogAdmin( calling_ply, str, steamid, time, reason )

				if targetPly then
					timer.Simple(0, function()
						if !IsValid(targetPly) then return end
						targetPly:Kick(reason)
					end)
				end
			end
		end

		ULib.queueFunctionCall(SBAN_dobanID, (targetPly and targetPly:IPAddress() or "unknown"), steamid, (name and name or "[Unknown]"), minutes*60, reason, calling_ply, cb)
	end
end

local sbanid = ulx.command( CATEGORY_NAME, "ulx sbanid", ulx.sbanid )
sbanid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
sbanid:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
sbanid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
sbanid:addParam{ type=ULib.cmds.BoolArg, invisible=true }
sbanid:defaultAccess( ULib.ACCESS_SUPERADMIN )
sbanid:help( "Bans steamid." )
sbanid:setOpposite( "ulx unsbanid", {_, _, 0, _, true}, "!unsbanid" )

------------------------------ Vote SBan ------------------------------

local function voteSBanDone2( t, target, time, ply, reason )
	local shouldBan = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logUserAct( ply, target, "#A approved the votesban against #T (" .. ULib.secondsToStringTime(time*60,true) .. ") (" .. (reason or "") .. ")" )
		shouldBan = true
	else
		ulx.logUserAct( ply, target, "#A denied the votesban against #T" )
	end

	if shouldBan then
		local adminID = ply.sb.aid or 0
		reason = reason .. " by ["..ply:SteamID().."]"

		local function cb(r)
			if r.added then
				local timeBan = time!=0 and ULib.secondsToStringTime(time*60,true) or "permanently"
				local str = "#A banned #T "..(time!=0 and"for "or"").."#s"..((reason and reason ~= "") and " (#s)" or "")
				ulx.fancyLogAdmin( ply, str, target, timeBan, reason )
			end
		end
		ULib.queueFunctionCall( SBAN_banplayer, target, time*60, reason, adminID, cb)
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
		str = "Vote results: User will now be banned for " .. ULib.secondsToStringTime(time*60,true) .. ", pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
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
		ULib.tsayError( calling_ply, "Error: Specify the reason of ban!", true )
		return
	end

	local msg = "[SB] Ban " .. target_ply:Nick() .. " for " .. ULib.secondsToStringTime(minutes*60,true) .. "?"
	
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "Yes", "No" }, voteSBanDone, _, _, _, target_ply, minutes, calling_ply, reason )

	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A started a votesban of #s against #T (#s)", ULib.secondsToStringTime(minutes*60,true), target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A started a votesban of #s against #T", ULib.secondsToStringTime(minutes*60,true), target_ply)
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