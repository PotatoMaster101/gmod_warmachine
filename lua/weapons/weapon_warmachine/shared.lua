AddCSLuaFile()

-- Weapon description
SWEP.PrintName = "War Machine"
SWEP.Author = "PotatoMaster101"
SWEP.Purpose = "Become the one and only War Machine."
SWEP.Category = "Marvel Comics By PotatoMaster101"

-- Spawn settings
SWEP.Spawnable = true
SWEP.AdminOnly = false

-- Primary attack
SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 300
SWEP.Primary.Delay = 0.5

-- Secondary attack
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true

-- Weapon settings
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = false
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = ""
SWEP.ViewModelFOV = 52

-- Weapon mode settings
SWEP.Mode = 0
SWEP.MaxModes = 3
SWEP.NextReload = 0
SWEP.ReloadDelay = 0.5
SWEP.ReloadSound = "Weapon_IRifle.Empty"

-- Player properties
SWEP.MaxHealth = 500
SWEP.Regen = 1
SWEP.FlightEnabled = true

-- Hide the excess material from c_arms_citizen.
function SWEP:PreDrawViewModel(vm, wep, ply)
    vm:SetMaterial("engine/occlusionproxy")
end

-- Initialize the SWEP.
function SWEP:Initialize()
    self:SetWeaponHoldType("fist")
end

-- Called when switched to this weapon.
function SWEP:Deploy()
    -- show fists
    local fist = self.Owner:GetViewModel()
    fist:ResetSequence(fist:LookupSequence("fists_draw"))
    self:Idle()
end

-- When idle, play idle animation.
function SWEP:Idle()
    local fist = self.Owner:GetViewModel()
    local idle = fist:LookupSequence("fists_idle_0" .. math.random(1, 2))
    timer.Create("idle" .. self:EntIndex(), fist:SequenceDuration(), 1,
        function() fist:ResetSequence(idle)
    end)
end

-- When SWEP got removed, remove timer too.
function SWEP:OnRemove()
    if (IsValid(self.Owner)) then
        local fist = self.Owner:GetViewModel()
        if (IsValid(fist)) then
            fist:SetMaterial("")
        end
    end
    timer.Stop("idle" .. self:EntIndex())
end

-- When changing weapon.
function SWEP:Holster(wep)
    self:OnRemove()
    return true
end

-- Perform basic punching in primary attack.
function SWEP:PrimaryAttack()
    local attacks = {"fists_left", "fists_right"}
    local chosen = attacks[math.random(1, #attacks)]
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    if (SERVER) then
        local fist = self.Owner:GetViewModel()
        fist:ResetSequence(fist:LookupSequence("fists_idle_01"))
        timer.Simple(0, function()
            local fist = self.Owner:GetViewModel()
            fist:ResetSequence(fist:LookupSequence(chosen))
            self:Idle()
        end)
    end

    -- wait for animation
    timer.Simple(0.2, function() self:SuperPunch() end)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

-- Perform secondary attack based on attack mode.
function SWEP:SecondaryAttack()
    if (self.Mode == 0) then        -- minigun
        self:Minigun()
        self:SetNextSecondaryFire(CurTime() + 0.05)
    elseif (self.Mode == 1) then    -- missile
        for i = 0.0, 0.9, 0.1 do
            timer.Simple(i, function()
                if (IsValid(self)) then     -- incase the player died
                    self:Missiles()
                end
            end)
        end
        self:SetNextSecondaryFire(CurTime() + 3)
    elseif (self.Mode == 2) then    -- unibeam laser
        self:Laser()
    elseif (self.Mode == 3) then    -- unibeam blast
        self:Unibeam()
        self:SetNextSecondaryFire(CurTime() + 2)
    end
end

-- Change attack mode on reload.
function SWEP:Reload()
    if (CurTime() < self.NextReload) then return end

    self.NextReload = CurTime() + self.ReloadDelay
    self.Mode = self.Mode + 1
    if (self.Mode > self.MaxModes) then
        self.Mode = 0
    end
    self:EmitSound(self.ReloadSound)
end

-- Runs every game tick.
function SWEP:Think()
    -- add health
    if (self.Owner:Health() < self.MaxHealth) then
        self.Owner:SetHealth(self.Owner:Health() + self.Regen)
    else
        self.Owner:SetHealth(self.MaxHealth)
    end

    -- flight
    self:Fly()
end

-- Fire minigun.
function SWEP:Minigun()
    bullet = {}
    bullet.AmmoType = "SMG1"
    bullet.Damage = 25
    bullet.Src = self.Owner:GetShootPos()
    bullet.Dir = self.Owner:GetAimVector()
    self.Owner:FireBullets(bullet)
    self:EmitSound("Weapon_Pistol.Single")
end

-- Fire missiles.
function SWEP:Missiles()
    if (!SERVER) then return end
    local rocket = ents.Create("warmachine_missile")
    if (!IsValid(rocket)) then return end

    rocket:SetPos(self.Owner:EyePos() + Vector(0, 0, 15))
    rocket:SetOwner(self.Owner)
    rocket:SetAngles(self.Owner:EyeAngles())
    rocket:Spawn()
    rocket:Launch()
end

-- Fire continuous laser beam.
function SWEP:Laser()
    -- laser effects
    local tr = self.Owner:GetEyeTrace()
    local eff = EffectData()
    if (!tr.Hit) then return end
    -- effect for laser beam
    eff:SetStart(self.Owner:EyePos() + Vector(0, 0, -12))
    eff:SetOrigin(tr.HitPos)
    util.Effect("warmachine_unibeam", eff)
    -- effect for sparks
    eff:SetStart(self.Owner:GetPos())
    eff:SetOrigin(tr.HitPos)
    util.Effect("cball_explode", eff)

    -- laser damage
    if (SERVER and (tr.Entity:IsPlayer() or tr.Entity:IsNPC())) then
        tr.Entity:TakeDamage(50, self.Owner, self)
    end
end

-- Fire unibeam.
function SWEP:Unibeam()
    local tr = self.Owner:GetEyeTrace()
    local eff = EffectData()
    if (!tr.Hit) then return end
    eff:SetStart(self.Owner:EyePos() + Vector(0, 0, -12))
    eff:SetOrigin(tr.HitPos)
    for i = 0, 1, 1 do
        util.Effect("warmachine_unibeam", eff)
    end

    if (!SERVER) then return end
    local exp = ents.Create("env_explosion")
    if (!IsValid(exp)) then return end
    exp:SetOwner(self.Owner)
    exp:SetPos(tr.HitPos)
    exp:SetKeyValue("iMagnitude", 1000)
    exp:SetKeyValue("iRadiusOverride", 150)
    exp:Spawn()
    exp:Fire("explode")
    exp:Fire("kill")
end

-- Perform a super punch
function SWEP:SuperPunch()
    local tr = self.Owner:GetEyeTrace()
    local pos = self.Owner:GetShootPos()
    if (tr.Hit and (tr.HitPos:Distance(pos) <= 125)) then   -- punch range 125
        -- punch
        bullet = {}
        bullet.Num = 1
        bullet.Force = self.Primary.Damage
        bullet.Damage = self.Primary.Damage
        bullet.Src = pos
        bullet.Dir = self.Owner:GetAimVector()
        self.Owner:FireBullets(bullet)

        -- effects
        local eff = EffectData()
        eff:SetStart(self.Owner:GetPos())
        eff:SetOrigin(tr.HitPos)
        util.Effect("StunstickImpact", eff)
        self:EmitSound("Weapon_PhysCannon.Launch")
        util.ScreenShake(self.Owner:GetPos(), 2, 2, 2, 5000)
    end
end

-- Perform flight.
function SWEP:Fly()
    if (!SERVER or !self.FlightEnabled) then return end

    if (self.Owner:KeyDown(IN_JUMP)) then
        self.Owner:SetVelocity(self.Owner:GetUp() * 30)
    end
    if (self.Owner:KeyDown(IN_FORWARD)) then
        self.Owner:SetVelocity(self.Owner:GetForward() * 30)
    end
    if (self.Owner:KeyDown(IN_BACK)) then
        self.Owner:SetVelocity(self.Owner:GetForward() * -30)
    end
    if (self.Owner:KeyDown(IN_MOVELEFT)) then
        self.Owner:SetVelocity(self.Owner:GetRight() * -20)
    end
    if (self.Owner:KeyDown(IN_MOVERIGHT)) then
        self.Owner:SetVelocity(self.Owner:GetRight() * 20)
    end
end
