-- MiRetrato: cambia el retrato del personaje (la foto junto a la vida)
local ADDON_NAME = ...
local RUTA_IMAGENES = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Imagenes\\"
local CIRCULOS_CLASE = "Interface\\TargetingFrame\\UI-Classes-Circles"

-- Iconos rápidos para elegir desde la ventana
local PREDEFINIDOS = {
    "Interface\\Icons\\Spell_Nature_Polymorph",
    "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
    "Interface\\Icons\\Ability_Racial_BearForm",
    "Interface\\Icons\\Ability_Mount_JungleTiger",
    "Interface\\Icons\\Ability_Stealth",
    "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    "Interface\\Icons\\Spell_Fire_FlameBolt",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    "Interface\\Icons\\Spell_Nature_Lightning",
    "Interface\\Icons\\Spell_Holy_HolyBolt",
    "Interface\\Icons\\INV_Sword_04",
    "Interface\\Icons\\INV_Shield_06",
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "Interface\\Icons\\INV_Misc_Gem_Pearl_05",
}

local db
local aplicando = false

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------
local function Mensaje(txt)
    print("|cffffcc33[MiRetrato]|r " .. txt)
end

local function Retrato()
    if PlayerFrame then
        local c = PlayerFrame.PlayerFrameContainer
        if c and c.PlayerPortrait then return c.PlayerPortrait end -- Retail
        if PlayerFrame.portrait then return PlayerFrame.portrait end
    end
    return _G.PlayerPortrait -- Classic
end

-- Pone una textura redondeada (como un retrato normal) si el cliente lo permite
local function PonerRedondo(tex, ruta)
    tex:SetTexCoord(0, 1, 0, 1)
    if SetPortraitToTexture and pcall(SetPortraitToTexture, tex, ruta) then return end
    tex:SetTexture(ruta)
end

-- Convierte lo que escribe el usuario en una ruta/ID de textura
local function Resolver(valor)
    if not valor or valor == "" then return nil end
    local num = tonumber(valor)
    if num then
        -- Puede ser un ID de hechizo o directamente un fileID de textura
        local icono
        if C_Spell and C_Spell.GetSpellTexture then
            icono = C_Spell.GetSpellTexture(num)
        elseif GetSpellTexture then
            icono = GetSpellTexture(num)
        end
        return icono or num
    end
    if valor:find("[\\/]") then
        return (valor:gsub("/", "\\"))
    end
    -- Nombre corto: primero se busca un icono del juego, si no, una imagen propia
    if valor:lower():find("^inv_") or valor:lower():find("^spell_")
        or valor:lower():find("^ability_") or valor:lower():find("^achievement_") then
        return "Interface\\Icons\\" .. valor
    end
    return RUTA_IMAGENES .. valor:gsub("%.tga$", ""):gsub("%.blp$", "")
end

---------------------------------------------------------------------------
-- Aplicar el retrato
---------------------------------------------------------------------------
local function Aplicar()
    if not db or aplicando then return end
    local tex = Retrato()
    if not tex then return end
    aplicando = true

    if db.modo == "clase" then
        local _, clase = UnitClass("player")
        local coords = clase and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[clase]
        if coords then
            tex:SetTexture(CIRCULOS_CLASE)
            tex:SetTexCoord(unpack(coords))
        end
    elseif db.modo == "textura" and db.textura then
        PonerRedondo(tex, db.textura)
    end

    aplicando = false
end

local function Restaurar()
    local tex = Retrato()
    if not tex then return end
    tex:SetTexCoord(0, 1, 0, 1)
    SetPortraitTexture(tex, "player")
end

local function Elegir(modo, textura)
    db.modo = modo
    db.textura = textura
    if modo == "defecto" then
        Restaurar()
    else
        Aplicar()
    end
end

-- El juego vuelve a poner el retrato original a menudo (al cambiar de zona,
-- montarse, etc.). Nos colgamos de esa función para volver a poner el nuestro.
hooksecurefunc("SetPortraitTexture", function(tex, unidad)
    if db and db.modo ~= "defecto" and tex == Retrato() then
        Aplicar()
    end
end)

---------------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------------
local COLUMNAS, TAM, SEP = 4, 40, 6

local f = CreateFrame("Frame", "MiRetratoFrame", UIParent, "BackdropTemplate")
f:SetSize(16 * 2 + COLUMNAS * TAM + (COLUMNAS - 1) * SEP + 40, 360)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
f:SetMovable(true)
f:EnableMouse(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "MiRetratoFrame") -- se cierra con Esc

local titulo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titulo:SetPoint("TOP", 0, -14)
titulo:SetText("MiRetrato")

local cerrar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
cerrar:SetPoint("TOPRIGHT", -4, -4)

-- Rejilla de iconos
local rejilla = CreateFrame("Frame", nil, f)
rejilla:SetSize(COLUMNAS * TAM + (COLUMNAS - 1) * SEP, 1)
rejilla:SetPoint("TOP", 0, -40)

for i, ruta in ipairs(PREDEFINIDOS) do
    local b = CreateFrame("Button", nil, rejilla)
    b:SetSize(TAM, TAM)
    local col = (i - 1) % COLUMNAS
    local fila = math.floor((i - 1) / COLUMNAS)
    b:SetPoint("TOPLEFT", col * (TAM + SEP), -fila * (TAM + SEP))
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints()
    t:SetTexture(ruta)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", function() Elegir("textura", ruta) end)
end

local filas = math.ceil(#PREDEFINIDOS / COLUMNAS)
local yAbajo = -40 - filas * (TAM + SEP) - 6

-- Caja de texto para imagen propia / icono / ID de hechizo
local etiqueta = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
etiqueta:SetPoint("TOPLEFT", 22, yAbajo)
etiqueta:SetText("Imagen, icono o ID de hechizo:")

local caja = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
caja:SetSize(f:GetWidth() - 90, 20)
caja:SetPoint("TOPLEFT", 26, yAbajo - 16)
caja:SetAutoFocus(false)
caja:SetScript("OnEscapePressed", caja.ClearFocus)

local function UsarCaja()
    local v = strtrim(caja:GetText() or "")
    local tex = Resolver(v)
    if tex then
        Elegir("textura", tex)
        Mensaje("Retrato cambiado a: " .. tostring(tex))
    end
    caja:ClearFocus()
end
caja:SetScript("OnEnterPressed", UsarCaja)

local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
ok:SetSize(40, 22)
ok:SetPoint("LEFT", caja, "RIGHT", 4, 0)
ok:SetText("OK")
ok:SetScript("OnClick", UsarCaja)

local function Boton(texto, x, accion)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(100, 22)
    b:SetPoint("BOTTOM", x, 16)
    b:SetText(texto)
    b:SetScript("OnClick", accion)
    return b
end
Boton("Icono de clase", -52, function() Elegir("clase") end)
Boton("Original", 52, function() Elegir("defecto") end)

f:SetHeight(-yAbajo + 16 + 20 + 16 + 22 + 20)

---------------------------------------------------------------------------
-- Comandos
---------------------------------------------------------------------------
SLASH_MIRETRATO1 = "/retrato"
SLASH_MIRETRATO2 = "/miretrato"
SlashCmdList.MIRETRATO = function(msg)
    msg = strtrim(msg or "")
    local cmd, resto = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" then
        f:SetShown(not f:IsShown())
    elseif cmd == "clase" then
        Elegir("clase")
        Mensaje("Retrato: icono de tu clase.")
    elseif cmd == "quitar" or cmd == "original" or cmd == "reset" then
        Elegir("defecto")
        Mensaje("Retrato original restaurado.")
    elseif cmd == "imagen" and resto ~= "" then
        Elegir("textura", RUTA_IMAGENES .. resto:gsub("%.tga$", ""):gsub("%.blp$", ""))
        Mensaje("Retrato: imagen '" .. resto .. "'.")
    elseif cmd == "icono" and resto ~= "" then
        local tex = Resolver(resto)
        Elegir("textura", tex)
        Mensaje("Retrato: " .. tostring(tex))
    else
        Mensaje("Comandos:")
        print("  /retrato  - abre la ventana")
        print("  /retrato imagen <nombre>  - usa Imagenes\\<nombre>.tga")
        print("  /retrato icono <ID hechizo | ruta | INV_xxx>")
        print("  /retrato clase  - icono de tu clase")
        print("  /retrato quitar  - vuelve al retrato normal")
    end
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------
local eventos = CreateFrame("Frame")
eventos:RegisterEvent("ADDON_LOADED")
eventos:RegisterEvent("PLAYER_ENTERING_WORLD")
eventos:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
eventos:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player")
eventos:SetScript("OnEvent", function(self, evento, arg1)
    if evento == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        MiRetratoDB = MiRetratoDB or {}
        db = MiRetratoDB
        db.modo = db.modo or "defecto"
        self:UnregisterEvent("ADDON_LOADED")
        return
    end
    if db and db.modo ~= "defecto" then
        Aplicar()
        -- El marco del jugador a veces se redibuja justo después del evento
        C_Timer.After(0.1, Aplicar)
    end
end)
