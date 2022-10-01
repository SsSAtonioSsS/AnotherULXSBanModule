local ucl = ULib.ucl
--
local origquery = ucl.query

function ucl.query(ply, access, hide)
    if ply:IsValid() then
        ply.sb = ply.sb or {}

        if type(ply.sb.password) == "string" and not table.HasValue(ucl.groups[ULib.ACCESS_ALL].allow, access) then
            ULib.tsayError(ply, "[SB-API] Ты забыл ввести свой пароль, " .. ply:Nick() .. ", (" .. access .. ")!", true)

            return false
        end
    end

    return origquery(ply, access, hide)
end

hook.Add(ULib.HOOK_PLAYER_TARGET, "SBAN_SATarget", function(ply, cmd, target)
    if ply.sb and ply.sb.sa then
        return true
    end
end)

hook.Add(ULib.HOOK_PLAYER_TARGETS, "SBAN_SATargets", function(ply, cmd, targets)
    if ply.sb and ply.sb.sa then
        return true
    end
end)

local meta = FindMetaTable("Player")
if not meta then return end
local origIsAdmin = meta.IsAdmin
local origIsSuperAdmin = meta.IsSuperAdmin

function meta:IsAdmin()
    if self.sb and self.sb.sa then
        return true
    elseif ucl.groups[ULib.ACCESS_ADMIN] then
        return self:CheckGroup(ULib.ACCESS_ADMIN)
    else -- Group doesn't exist, fall back on garry's method
        return origIsAdmin(self)
    end
end

function meta:IsSuperAdmin()
    if self.sb and self.sb.sa then
        return true
    elseif ucl.groups[ULib.ACCESS_SUPERADMIN] then
        return self:CheckGroup(ULib.ACCESS_SUPERADMIN)
    else -- Group doesn't exist, fall back on garry's method
        return origIsSuperAdmin(self)
    end
end