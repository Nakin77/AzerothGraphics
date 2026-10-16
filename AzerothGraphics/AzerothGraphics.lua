local ADDON_NAME, ns = ...
local L = ns.L -- texts in the client's language (Locales.lua)

-- Name shown in game.
local TITLE = "Azeroth Graphics"

local CVarGet = (C_CVar and C_CVar.GetCVar) or GetCVar
local CVarSet = (C_CVar and C_CVar.SetCVar) or SetCVar
local CVarDefault = (C_CVar and C_CVar.GetCVarDefault) or GetCVarDefault

-- Each entry: the CVar, how it is shown, and the value restored by the default button.
-- Entries without a default use the game's own default for that CVar.
-- "Set all to maximum" moves sliders to max, or to best when max shows less.
-- Header entries start a new section.
local SETTINGS = {
    { header = L.HEADER_GROUND },
    {
        cvar = "groundEffectDensity", kind = "slider", default = 48, min = 16, max = 256, step = 8,
        label = L.GRASS_DENSITY, desc = L.GRASS_DENSITY_DESC,
    },
    {
        cvar = "groundEffectDist", kind = "slider", default = 200, min = 0, max = 500, step = 10,
        label = L.GRASS_DISTANCE, desc = L.GRASS_DISTANCE_DESC,
    },
    {
        cvar = "groundEffectFade", kind = "slider", default = 70, min = 0, max = 500, step = 10,
        label = L.GRASS_FADE, desc = L.GRASS_FADE_DESC,
    },

    { header = L.HEADER_VIEW },
    {
        cvar = "terrainLodDist", kind = "slider", min = 100, max = 1000, step = 10,
        label = L.TERRAIN_DETAIL, desc = L.TERRAIN_DETAIL_DESC,
    },
    {
        cvar = "lodObjectFadeScale", kind = "slider", min = 0, max = 300, step = 10,
        label = L.OBJECT_DISTANCE, desc = L.OBJECT_DISTANCE_DESC,
    },
    {
        cvar = "lodObjectCullSize", kind = "slider", min = 0, max = 50, step = 1, best = 0,
        label = L.SMALL_OBJECTS, desc = L.SMALL_OBJECTS_DESC,
    },

    { header = L.HEADER_IMAGE },
    {
        cvar = "ResampleAlwaysSharpen", kind = "check", default = 0,
        label = L.SHARPEN, desc = L.SHARPEN_DESC,
    },
    {
        cvar = "reflectionMode", kind = "slider", min = 0, max = 3, step = 1,
        label = L.WATER_REFLECTIONS, desc = L.WATER_REFLECTIONS_DESC,
    },
    {
        cvar = "weatherDensity", kind = "slider", min = 0, max = 3, step = 1,
        label = L.WEATHER, desc = L.WEATHER_DESC,
    },
    {
        cvar = "ffxDeath", kind = "check", default = 1,
        label = L.DEATH_EFFECT, desc = L.DEATH_EFFECT_DESC,
    },
}

-- "global" applies everywhere. Each other configuration, once enabled, replaces
-- it inside instances of its type (keys are the instance types of IsInInstance).
-- A CVar left untouched in such a configuration keeps following global.
local PROFILES = {
    { key = "global", name = L.TAB_GLOBAL },
    { key = "party", name = L.TAB_PARTY, where = L.WHERE_PARTY },
    { key = "raid", name = L.TAB_RAID, where = L.WHERE_RAID },
    { key = "pvp", name = L.TAB_PVP, where = L.WHERE_PVP },
}
local PROFILE = {}
for _, p in ipairs(PROFILES) do PROFILE[p.key] = p end

-- AzerothGraphicsDB:
--   profiles.global.values[cvar]  forced value; nil leaves the CVar to the game
--   profiles.<type>.values[cvar]  value in that instance type; nil follows global
--   profiles.<type>.enabled
--   baseline[cvar]                game value to put back once an instance stops
--                                 forcing a CVar that global leaves to the game
local db
local context -- instance type of the current zone, when it has a configuration
local instances = {} -- every built set of controls (floating window, options panel)

local function Exists(s)
    return CVarGet(s.cvar) ~= nil
end

local function Default(s)
    if s.default == nil and CVarDefault then
        s.default = tonumber(CVarDefault(s.cvar) or "")
    end
    return s.default
end

local function Current(s)
    return tonumber(CVarGet(s.cvar) or "") or Default(s) or 0
end

local function Snap(s, v)
    return math.floor((v - s.min) / s.step + 0.5) * s.step + s.min
end

local function InitDB()
    AzerothGraphicsDB = AzerothGraphicsDB or {}
    db = AzerothGraphicsDB
    db.profiles = db.profiles or {}
    for _, p in ipairs(PROFILES) do
        local profile = db.profiles[p.key] or {}
        profile.values = profile.values or {}
        db.profiles[p.key] = profile
    end
    -- Up to 1.1, the only configuration was stored in db.values.
    if db.values then
        db.profiles.global.values = db.values
        db.values = nil
    end
    db.baseline = db.baseline or {}
end

-- Key of the configuration in use right now.
local function ActiveKey()
    local profile = context and db.profiles[context]
    return profile and profile.enabled and context or "global"
end

-- Value forced by the instance configuration in use, if any.
local function Override(s)
    local key = ActiveKey()
    if key ~= "global" then return db.profiles[key].values[s.cvar] end
end

-- Value the CVar has (or will have back) outside instances.
local function GlobalValue(s)
    local v = db.profiles.global.values[s.cvar]
    if v == nil then v = db.baseline[s.cvar] end
    if v == nil then v = Current(s) end
    return v
end

-- Value shown in a configuration's tab, and whether that configuration sets it itself.
local function ProfileValue(key, s)
    local v = key ~= "global" and db.profiles[key].values[s.cvar]
    if v then return v, true end
    return GlobalValue(s), false
end

-- Puts the CVar at the value of the configuration in use.
local function Apply(s)
    if not Exists(s) then return end
    local cvar = s.cvar
    local global = db.profiles.global.values[cvar]
    local target = Override(s)
    if target ~= nil then
        if global == nil and db.baseline[cvar] == nil then
            db.baseline[cvar] = Current(s)
        end
    else
        target = global
        if target == nil then target = db.baseline[cvar] end
        db.baseline[cvar] = nil
    end
    if target ~= nil and target ~= Current(s) then
        CVarSet(cvar, tostring(target))
    end
end

local function RefreshAll()
    for _, controls in ipairs(instances) do controls:Sync() end
end

local function ApplyAll()
    for _, s in ipairs(SETTINGS) do
        if s.cvar then Apply(s) end
    end
    RefreshAll()
end

-- Stores a value in a configuration. When that configuration drives the CVar
-- right now, writes it then reads it back, since the engine may clamp the value.
-- Global only remembers values that differ from the default.
local function SetValue(key, s, value)
    local cvar = s.cvar
    local isGlobal = key == "global"
    local live
    if isGlobal then live = Override(s) == nil else live = key == ActiveKey() end

    if live and Exists(s) then
        if not isGlobal and db.profiles.global.values[cvar] == nil and db.baseline[cvar] == nil then
            db.baseline[cvar] = Current(s)
        end
        CVarSet(cvar, tostring(value))
        value = Current(s)
        if isGlobal then db.baseline[cvar] = nil end
    end

    if not isGlobal then
        db.profiles[key].values[cvar] = value
    elseif value ~= Default(s) then
        db.profiles.global.values[cvar] = value
    else
        db.profiles.global.values[cvar] = nil
        -- Overridden by the current instance: the default is put back on leaving it.
        if not live then db.baseline[cvar] = value end
    end
end

local function ResetAll()
    for _, s in ipairs(SETTINGS) do
        if s.cvar and Exists(s) and Default(s) then SetValue("global", s, Default(s)) end
    end
    RefreshAll()
end

-- Moves every slider of a configuration to its most detailed value.
-- Checkboxes are preferences rather than quality levels, so they stay as they are.
local function MaxAll(key)
    for _, s in ipairs(SETTINGS) do
        if s.kind == "slider" and Exists(s) then SetValue(key, s, s.best or s.max) end
    end
    RefreshAll()
end

-- Makes a CVar of an instance configuration follow global again.
local function ClearOverride(key, s)
    db.profiles[key].values[s.cvar] = nil
    Apply(s)
    RefreshAll()
end

local function ClearProfile(key)
    wipe(db.profiles[key].values)
    ApplyAll()
end

local function ShowTooltip(owner, s)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(s.label, 1, 0.82, 0)
    GameTooltip:AddLine(s.desc, 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L.TIP_DEFAULT, tostring(Default(s) or "?"), 0.6, 0.6, 0.6, 1, 1, 1)
    if s.kind == "slider" then
        GameTooltip:AddDoubleLine(L.TIP_RANGE, L.RANGE:format(s.min, s.max), 0.6, 0.6, 0.6, 1, 1, 1)
    end
    GameTooltip:AddDoubleLine(L.TIP_CVAR, s.cvar, 0.6, 0.6, 0.6, 1, 1, 1)
    if s.kind == "slider" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.TIP_TYPE, 0.6, 0.8, 1, true)
    end
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- One tab per configuration, then one line per CVar: label column, control
-- column, value box, and a button back to the default (or, in an instance
-- configuration, back to the global value).
local LABEL_X = 20
local CONTROL_X = 230
local SLIDER_W = 200
local RESET_X = CONTROL_X + SLIDER_W + 82 -- past the value box
local RESET_W = 90
local WIDTH = RESET_X + RESET_W + 10
local EDGE = LABEL_X - 4 -- side margin of the tabs and section lines
local ROW_H = 36
local TAB_H = 24
local TAB_GAP = 4

-- Builds the tabs, the sections with one row per CVar, and the "reset all"
-- button inside parent, starting at y (offset from parent's top). Returns the
-- controls and the y below the last widget.
local function CreateControls(parent, y)
    local controls = { key = "global", tabs = {}, rows = {} }
    local syncing = false

    -- Selected tab in white, enabled configurations in gold, disabled ones in grey.
    local tabW = (WIDTH - 2 * EDGE - (#PROFILES - 1) * TAB_GAP) / #PROFILES
    for i, p in ipairs(PROFILES) do
        local tab = CreateFrame("Button", nil, parent)
        tab:SetSize(tabW, TAB_H)
        tab:SetPoint("TOPLEFT", EDGE + (i - 1) * (tabW + TAB_GAP), y)
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        local underline = tab:CreateTexture(nil, "ARTWORK")
        underline:SetColorTexture(1, 0.82, 0, 1)
        underline:SetPoint("BOTTOMLEFT")
        underline:SetPoint("BOTTOMRIGHT")
        underline:SetHeight(2)
        local highlight = tab:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetColorTexture(1, 1, 1, 0.08)
        highlight:SetAllPoints()
        local text = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("CENTER", 0, 1)
        text:SetText(p.name)
        tab:SetScript("OnClick", function() controls:Select(p.key) end)

        function tab:Refresh()
            local selected = controls.key == p.key
            bg:SetColorTexture(1, 1, 1, selected and 0.12 or 0.04)
            underline:SetShown(selected)
            if selected then
                text:SetTextColor(1, 1, 1)
            elseif p.key == "global" or db.profiles[p.key].enabled then
                text:SetTextColor(1, 0.82, 0)
            else
                text:SetTextColor(0.5, 0.5, 0.5)
            end
        end

        controls.tabs[i] = tab
    end
    y = y - TAB_H - 6

    -- Under the tabs: the enable checkbox of an instance configuration (a note
    -- for global) and, on the right, the configuration in use right now.
    local barY = y - 13
    local enable = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    enable:SetSize(26, 26)
    enable:SetPoint("LEFT", parent, "TOPLEFT", EDGE - 3, barY)
    local enableLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    enableLabel:SetPoint("LEFT", enable, "RIGHT", 2, 1)
    enable:SetScript("OnClick", function(self)
        db.profiles[controls.key].enabled = self:GetChecked() or nil
        ApplyAll()
    end)
    enable:SetScript("OnEnter", function(self)
        local p = PROFILE[controls.key]
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(p.name, 1, 0.82, 0)
        GameTooltip:AddLine(L.ENABLE_ON:format(p.where), 1, 1, 1, true)
        GameTooltip:AddLine(L.ENABLE_OFF:format(p.where), 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.ENABLE_KEEP, 0.6, 0.8, 1, true)
        GameTooltip:Show()
    end)
    enable:SetScript("OnLeave", HideTooltip)

    local globalNote = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    globalNote:SetPoint("LEFT", parent, "TOPLEFT", EDGE, barY)
    globalNote:SetText(L.GLOBAL_NOTE)

    local status = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetPoint("RIGHT", parent, "TOPLEFT", WIDTH - EDGE, barY)
    y = y - 30

    for _, s in ipairs(SETTINGS) do
        if s.header then
            y = y - 6
            local header = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            header:SetPoint("TOPLEFT", EDGE, y)
            header:SetText(s.header)
            local line = parent:CreateTexture(nil, "ARTWORK")
            line:SetColorTexture(1, 1, 1, 0.15)
            line:SetSize(WIDTH - 2 * EDGE, 1)
            line:SetPoint("TOPLEFT", EDGE, y - 16)
            y = y - 24
        else
            local row = { s = s }
            local centerY = y - ROW_H / 2

            -- Marks the rows an instance configuration sets itself.
            local accent = parent:CreateTexture(nil, "ARTWORK")
            accent:SetColorTexture(1, 0.82, 0, 0.9)
            accent:SetSize(3, ROW_H - 10)
            accent:SetPoint("TOPLEFT", LABEL_X - 10, y - 3)

            local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            label:SetPoint("TOPLEFT", LABEL_X, y - 4)
            label:SetText(s.label)
            local info = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            info:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)

            local inputs, Display
            if s.kind == "slider" then
                -- Drawn by hand so it stands out on any background: a framed
                -- groove, a gold fill up to the value, and a light outlined thumb.
                local slider = CreateFrame("Slider", nil, parent)
                slider:SetOrientation("HORIZONTAL")
                slider:SetSize(SLIDER_W, 18)
                slider:SetPoint("LEFT", parent, "TOPLEFT", CONTROL_X, centerY)
                slider:SetHitRectInsets(0, 0, -6, -6)

                local groove = slider:CreateTexture(nil, "BACKGROUND")
                groove:SetColorTexture(1, 1, 1, 0.3)
                groove:SetPoint("LEFT")
                groove:SetPoint("RIGHT")
                groove:SetHeight(8)
                local inner = slider:CreateTexture(nil, "BACKGROUND", nil, 1)
                inner:SetColorTexture(0, 0, 0, 0.9)
                inner:SetPoint("TOPLEFT", groove, 1, -1)
                inner:SetPoint("BOTTOMRIGHT", groove, -1, 1)
                local fill = slider:CreateTexture(nil, "BORDER")
                fill:SetColorTexture(1, 0.82, 0, 0.9)
                fill:SetPoint("LEFT", inner)
                fill:SetHeight(6)

                slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
                local thumb = slider:GetThumbTexture()
                thumb:SetDrawLayer("OVERLAY")
                thumb:SetSize(10, 18)
                thumb:SetVertexColor(0.85, 0.8, 0.65)
                local thumbEdge = slider:CreateTexture(nil, "ARTWORK")
                thumbEdge:SetColorTexture(0, 0, 0, 1)
                thumbEdge:SetPoint("TOPLEFT", thumb, -1, 1)
                thumbEdge:SetPoint("BOTTOMRIGHT", thumb, 1, -1)

                local function UpdateFill(v)
                    local fraction = math.max(0, math.min(1, (v - s.min) / (s.max - s.min)))
                    fill:SetWidth(math.max(fraction * (SLIDER_W - 2), 1))
                    fill:SetShown(fraction > 0)
                end

                slider:SetMinMaxValues(s.min, s.max)
                slider:SetValueStep(s.step)
                slider:SetObeyStepOnDrag(true)

                -- Typed values may go past the slider's range.
                local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
                box:SetSize(50, 20)
                box:SetPoint("LEFT", slider, "RIGHT", 18, 0)
                box:SetAutoFocus(false)
                box:SetNumeric(true)
                box:SetMaxLetters(5)
                box:SetJustifyH("CENTER")
                box:SetScript("OnEnterPressed", function(self)
                    local v = tonumber(self:GetText())
                    if v then row:Set(v) end
                    self:ClearFocus()
                end)
                box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
                box:SetScript("OnEditFocusLost", function() row:Refresh() end)

                -- Applied shortly after the slider stops moving, not on every step of a drag.
                slider:SetScript("OnValueChanged", function(_, v)
                    v = Snap(s, v)
                    box:SetText(tostring(v))
                    UpdateFill(v)
                    if syncing then return end
                    if row.timer then row.timer:Cancel() end
                    row.timer = C_Timer.NewTimer(0.15, function()
                        row.timer = nil
                        row:Set(v)
                    end)
                end)
                slider:SetScript("OnEnter", function(self)
                    thumb:SetVertexColor(1, 1, 1)
                    ShowTooltip(self, s)
                end)
                slider:SetScript("OnLeave", function()
                    thumb:SetVertexColor(0.85, 0.8, 0.65)
                    HideTooltip()
                end)

                function Display(v)
                    syncing = true
                    slider:SetValue(v)
                    syncing = false
                    box:SetText(tostring(v))
                    -- OnValueChanged does not fire when the value stays the same.
                    UpdateFill(slider:GetValue())
                end

                inputs = { slider, box }
            else
                local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
                cb:SetSize(26, 26)
                cb:SetPoint("LEFT", parent, "TOPLEFT", CONTROL_X - 4, centerY)
                cb:SetScript("OnClick", function(self) row:Set(self:GetChecked() and 1 or 0) end)
                cb:SetScript("OnEnter", function(self) ShowTooltip(self, s) end)
                cb:SetScript("OnLeave", HideTooltip)

                function Display(v)
                    cb:SetChecked(v ~= 0)
                end

                inputs = { cb }
            end

            local widgets = { label, info }
            for _, w in ipairs(inputs) do widgets[#widgets + 1] = w end

            local reset = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            reset:SetSize(RESET_W, 22)
            reset:SetPoint("LEFT", parent, "TOPLEFT", RESET_X, centerY)
            reset:SetScript("OnClick", function()
                if controls.key == "global" then
                    local def = Default(s)
                    if def then row:Set(def) end
                else
                    ClearOverride(controls.key, s)
                end
            end)
            reset:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if controls.key == "global" then
                    GameTooltip:AddLine(L.BUTTON_DEFAULT_TIP:format(tostring(Default(s) or "?")), 1, 1, 1, true)
                else
                    GameTooltip:AddLine(L.BUTTON_GLOBAL_TIP, 1, 1, 1, true)
                end
                GameTooltip:Show()
            end)
            reset:SetScript("OnLeave", HideTooltip)

            function row:Set(value)
                if self.timer then self.timer:Cancel() self.timer = nil end
                SetValue(controls.key, s, value)
                RefreshAll()
            end

            function row:Refresh()
                if self.timer then self.timer:Cancel() self.timer = nil end
                local key = controls.key
                local available = Exists(s)
                local def = Default(s)
                local v, own = ProfileValue(key, s)
                for _, w in ipairs(widgets) do w:SetAlpha(available and 1 or 0.4) end
                for _, w in ipairs(inputs) do w:EnableMouse(available) end
                if not available then
                    info:SetText(L.UNAVAILABLE)
                elseif key == "global" then
                    info:SetText(L.DEFAULT_VALUE:format(tostring(def or "?")))
                else
                    -- In gold, like the mark on the left, when this tab sets the value itself.
                    local origin = own and "|cffffd100" .. L.CHANGED_HERE .. "|r" or L.SAME_AS_GLOBAL
                    info:SetText(L.DEFAULT_VALUE:format(tostring(def or "?")) .. " · " .. origin)
                end
                accent:SetShown(key ~= "global" and own)
                Display(v)
                if key == "global" then
                    reset:SetText(L.BUTTON_DEFAULT)
                    reset:SetEnabled(available and def ~= nil and v ~= def)
                else
                    reset:SetText(L.BUTTON_GLOBAL)
                    reset:SetEnabled(available and own)
                end
            end

            controls.rows[#controls.rows + 1] = row
            y = y - ROW_H
        end
    end

    local resetAll = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetAll:SetSize(200, 24)
    resetAll:SetPoint("TOPLEFT", LABEL_X, y - 10)
    resetAll:SetScript("OnClick", function()
        if controls.key == "global" then ResetAll() else ClearProfile(controls.key) end
    end)

    local maxAll = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    maxAll:SetSize(200, 24)
    maxAll:SetPoint("LEFT", resetAll, "RIGHT", 10, 0)
    maxAll:SetText(L.MAX_ALL)
    maxAll:SetScript("OnClick", function() MaxAll(controls.key) end)
    maxAll:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.MAX_ALL, 1, 0.82, 0)
        GameTooltip:AddLine(L.MAX_ALL_TIP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    maxAll:SetScript("OnLeave", HideTooltip)
    y = y - 36

    function controls:Sync()
        if not db then return end
        local key = self.key
        local isGlobal = key == "global"
        for _, tab in ipairs(self.tabs) do tab:Refresh() end

        globalNote:SetShown(isGlobal)
        enable:SetShown(not isGlobal)
        enableLabel:SetShown(not isGlobal)
        if not isGlobal then
            enable:SetChecked(db.profiles[key].enabled == true)
            enableLabel:SetText(L.USE_HERE:format(PROFILE[key].where))
        end
        status:SetText(L.IN_USE:format("|cffffffff" .. PROFILE[ActiveKey()].name .. "|r"))

        if isGlobal then
            resetAll:SetText(L.RESET_ALL)
            resetAll:SetEnabled(true)
        else
            resetAll:SetText(L.RESET_ALL_GLOBAL)
            resetAll:SetEnabled(next(db.profiles[key].values) ~= nil)
        end

        for _, row in ipairs(self.rows) do row:Refresh() end
    end

    function controls:Select(key)
        self.key = key
        self:Sync()
    end

    -- Opens on the configuration in use, so what is shown is what is applied.
    parent:SetScript("OnShow", function() controls:Select(db and ActiveKey() or "global") end)
    instances[#instances + 1] = controls
    return controls, y
end

-- Floating window (/agfx), handy to watch the world while tweaking.
local window

local function CreateWindow()
    local f = CreateFrame("Frame", "AzerothGraphicsWindow", UIParent, "BackdropTemplate")
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.07, 0.06, 0.05, 0.96)
    f:SetBackdropBorderColor(0.48, 0.40, 0.27, 1)
    tinsert(UISpecialFrames, f:GetName())

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText(TITLE)

    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText(L.SUBTITLE)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)

    local _, bottom = CreateControls(f, -58)
    f:SetSize(WIDTH, -bottom + 12)
    f:Hide()
    return f
end

local function ToggleWindow()
    window = window or CreateWindow()
    window:SetShown(not window:IsShown())
end

function AzerothGraphics_OnAddonCompartmentClick()
    ToggleWindow()
end

-- Same controls in Esc > Options > AddOns.
local panel = CreateFrame("Frame")
panel.name = TITLE

local panelTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panelTitle:SetPoint("TOPLEFT", 16, -16)
panelTitle:SetText(TITLE)

local panelSub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panelSub:SetPoint("BOTTOMLEFT", panelTitle, "BOTTOMRIGHT", 12, 1)
panelSub:SetText(L.PANEL_HINT)

CreateControls(panel, -44)
-- A frame created without a parent starts out shown, so the options window
-- would display it without ever firing OnShow (and without filling the values).
panel:Hide()

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

SLASH_AZEROTHGRAPHICS1 = "/agfx"
SLASH_AZEROTHGRAPHICS2 = "/azerothgraphics"
SlashCmdList.AZEROTHGRAPHICS = function(msg)
    if strtrim(msg or ""):lower() == "reset" then
        ResetAll()
        print("|cff33ff99" .. TITLE .. "|r - " .. L.RESET_DONE)
    else
        ToggleWindow()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME then
            InitDB()
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    -- Switches configuration when entering or leaving an instance, and puts
    -- back the chosen values that graphics presets may have overwritten.
    local _, instanceType = IsInInstance()
    context = PROFILE[instanceType] and instanceType or nil
    ApplyAll()
end)
