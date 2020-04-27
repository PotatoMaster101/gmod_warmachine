AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Missile settings
ENT.Flying = false
ENT.Velocity = nil
ENT.Damage = 300
ENT.Radius = 100

-- Initialises the entity.
function ENT:Initialize()
    if (!SERVER) then return end    -- only server can spawn this

    self:SetModel("models/items/AR2_Grenade.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysWake()
end

-- Called when player spawns entity. Set spawn location and properties.
function ENT:SpawnFunction(ply, tr, cl)
    if (!tr.Hit) then return end
    local ent = ents.Create(cl)
    if (!IsValid(ent)) then return end

    ent:SetPos(tr.HitPos + (tr.HitNormal * 16))
    ent:SetOwner(ply)
    ent:SetName("Missile")
    ent:Spawn()
    ent:Activate()
    return ent
end

-- Runs every game tick.
function ENT:Think()
    -- if flying, keep flying and don't drop
    if (self.Flying) then
        local phys = self:GetPhysicsObject()
        if (IsValid(phys)) then
            phys:EnableGravity(false)
            phys:ApplyForceCenter(self.Velocity)
        end
    end
end

-- Called when missile collided, explode.
function ENT:PhysicsCollide(data, coll)
    timer.Simple(0, function()
        if (IsValid(self)) then
            self:Explode(self.Damage, self.Radius)
        end
    end)
end

-- Called when player pressed E on entity. Explode the missile.
function ENT:Use(activ, caller)
    if (IsValid(caller) and caller:IsPlayer()) then
        self:SetOwner(caller)
        self:Explode(self.Damage, self.Radius)
    end
end

-- Make the missile explode at impact.
function ENT:Explode(dmg, rad)
    local exp = ents.Create("env_explosion")
    if (!IsValid(exp)) then return end

    exp:SetPos(self:GetPos())
    exp:SetOwner(self.Owner)
    exp:SetKeyValue("iMagnitude", dmg)
    exp:SetKeyValue("iRadiusOverride", rad)
    self:Remove()
    exp:Spawn()
    exp:Fire("explode")
    exp:Fire("kill")
end

-- Make the missile launch forward.
function ENT:Launch()
    self.Flying = true
    self.Velocity = self.Owner:GetAimVector() * 100000
end
