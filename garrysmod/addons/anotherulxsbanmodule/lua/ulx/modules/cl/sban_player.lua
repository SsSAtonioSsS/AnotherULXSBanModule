local meta = FindMetaTable("Player")
oldisa = meta.IsAdmin
oldissa = meta.IsSuperAdmin

function meta:IsAdmin()
    if self.sa then
        return true
    else
        return oldisa(self)
    end
end

function meta:IsSuperAdmin()
    if self.sa then
        return true
    else
        return oldissa(self)
    end
end

local function isSAAccess()
    local ply = LocalPlayer()
    ply.sa = net.ReadBool()
end

net.Receive("sban_superadmin", isSAAccess)