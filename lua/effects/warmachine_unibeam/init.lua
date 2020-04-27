EFFECT.StartingPos = nil
EFFECT.EndingPos = nil
EFFECT.Color = Color(255, 0, 0, 255)
EFFECT.DieTime = nil

-- Called when effect created.
function EFFECT:Init(data)
    self.StartingPos = data:GetStart()
    self.EndingPos = data:GetOrigin()
    self.DieTime = CurTime() + 0.013
    self.Entity:SetRenderBoundsWS(self.StartingPos, self.EndingPos)
end

-- Called every game tick.
function EFFECT:Think()
    -- die after time reached
    if (CurTime() > self.DieTime) then
        return false
    end
    return true
end

-- Called when effect is rendered.
function EFFECT:Render()
    render.SetMaterial(Material("cable/redlaser"))
    render.DrawBeam(self.StartingPos, self.EndingPos, 20, 0, 0, self.Color)
end
