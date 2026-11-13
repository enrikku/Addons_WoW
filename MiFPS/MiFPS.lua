-- MiFPS: muestra los FPS y la latencia en tiempo real
local INTERVALO = 0.25 -- segundos entre actualizaciones

local DEFAULTS = {
    punto = "TOP", x = 0, y = -20,
    bloqueado = false,
    oculto = false,
    latencia = true,
    escala = 1,
}

local db

local function Mensaje(txt)
    print("|cff33ff99[MiFPS]|r " .. txt)
end

-- Verde >= 60, amarillo >= 30, rojo por debajo
local function ColorFPS(fps)
    if fps >= 60 then return "|cff00ff00"
    elseif fps >= 30 then return "|cffffff00"
    else return "|cffff3333" end
end

local function ColorMS(ms)
    if ms < 100 then return "|cff00ff00"
    elseif ms < 250 then return "|cffffff00"
    else return "|cffff3333" end
end

---------------------------------------------------------------------------
-- Marco
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "MiFPSFrame", UIParent, "BackdropTemplate")
f:SetSize(110, 24)
f:SetFrameStrata("HIGH")
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetBackdrop({
    bgFile = "Interface\Buttons\WHITE8X8",
    edgeFile = "Interface\Buttons\WHITE8X8",
    edgeSize = 1,
})
f:SetBackdropColor(0, 0, 0, 0.5)
f:SetBackdropBorderColor(0, 0, 0, 0.8)

local texto = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
texto:SetPoint("CENTER")
texto:SetText("-- fps")

local function GuardarPosicion()
    local punto, _, _, x, y = f:GetPoint()
    db.punto, db.x, db.y = punto, x, y
end

local function AplicarPosicion()
    f:ClearAllPoints()
    f:SetPoint(db.punto, UIParent, db.punto, db.x, db.y)
    f:SetScale(db.escala)
end

f:SetScript("OnDragStart", function(self)
    if not db.bloqueado then self:StartMoving() end
end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    GuardarPosicion()
end)

-- Tooltip con detalle
f:SetScript("OnEnter", function(self)
    local _, _, casa, mundo = GetNetStats()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("MiFPS")
    GameTooltip:AddDoubleLine("FPS:", string.format("%.1f", GetFramerate()), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Latencia local:", casa .. " ms", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Latencia mundo:", mundo .. " ms", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(db.bloqueado and "Bloqueado (/fps lock)" or "Arrastra para mover", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
f:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Actualización
local acumulado = 0
f:SetScript("OnUpdate", function(self, elapsed)
    acumulado = acumulado + elapsed
    if acumulado < INTERVALO then return end
    acumulado = 0

    local fps = GetFramerate()
    local s = ColorFPS(fps) .. string.format("%d", fps) .. "|r fps"
    if db.latencia then
        local _, _, casa, mundo = GetNetStats()
        local ms = math.max(casa, mundo)
        s = s .. "  " .. ColorMS(ms) .. ms .. "|r ms"
    end
    texto:SetText(s)
    self:SetWidth(texto:GetStringWidth() + 16)
end)

---------------------------------------------------------------------------
-- Carga
---------------------------------------------------------------------------
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, nombre)
    if nombre ~= "MiFPS" then return end
    MiFPSDB = MiFPSDB or {}
    db = MiFPSDB
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    AplicarPosicion()
    f:SetShown(not db.oculto)
    self:UnregisterEvent("ADDON_LOADED")
end)

---------------------------------------------------------------------------
-- Comandos
---------------------------------------------------------------------------
SLASH_MIFPS1 = "/fps"
SLASH_MIFPS2 = "/mifps"
SlashCmdList["MIFPS"] = function(msg)
    msg = strlower(strtrim(msg or ""))
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")

    if cmd == "" or cmd == "toggle" then
        db.oculto = not db.oculto
        f:SetShown(not db.oculto)
        Mensaje(db.oculto and "Oculto." or "Visible.")
    elseif cmd == "lock" then
        db.bloqueado = not db.bloqueado
        Mensaje(db.bloqueado and "Posición bloqueada." or "Posición desbloqueada (arrastra para mover).")
    elseif cmd == "ms" then
        db.latencia = not db.latencia
        Mensaje("Latencia " .. (db.latencia and "activada." or "desactivada."))
    elseif cmd == "escala" then
        local n = tonumber(arg)
        if n and n >= 0.5 and n <= 3 then
            db.escala = n
            AplicarPosicion()
            Mensaje("Escala: " .. n)
        else
            Mensaje("Uso: /fps escala 0.5-3")
        end
    elseif cmd == "reset" then
        for k, v in pairs(DEFAULTS) do db[k] = v end
        AplicarPosicion()
        f:Show()
        Mensaje("Configuración restablecida.")
    else
        Mensaje("Comandos:")
        print("  /fps - mostrar/ocultar")
        print("  /fps lock - bloquear/desbloquear posición")
        print("  /fps ms - mostrar/ocultar latencia")
        print("  /fps escala <0.5-3> - tamaño")
        print("  /fps reset - restablecer")
    end
end
