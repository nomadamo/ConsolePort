---------------------------------------------------------------
local _, env = ...; local db = env.db;
---------------------------------------------------------------
local Bar = env.Frame;
local cfg

local Clusters = env.libs.clusters;

local BAR_MIN_WIDTH    = 1105
local BAR_MAX_SCALE    = 1.6
local BAR_FIXED_HEIGHT = 140

-- Opacity handling
---------------------------------------------------------------
function Bar:FadeIn(alpha, time)
	if self.forceFadeOut then return end;
	db.Alpha.FadeIn(self, time or .25, alpha or 0, 1)
end

function Bar:FadeOut(alpha, time)
	db.Alpha.FadeOut(self, time or 1, alpha or 1, 0)
end

db:RegisterCallback('OnHintsClear', function(self)
	self.forceFadeOut = false;
	if not env:GetValue('hidebar') or InCombatLockdown() then
		self:FadeIn(self:GetAlpha())
	end
end, Bar)

db:RegisterCallback('OnHintsFocus', function(self)
	self.forceFadeOut = true;
	self:FadeOut(self:GetAlpha(), .1)
end, Bar)

-- Global movement
---------------------------------------------------------------
function Bar:ToggleMovable(enableMouseDrag, enableMouseWheel)
	if enableMouseDrag then
		self:RegisterForDrag('LeftButton')
	end
	self:EnableMouse(not not enableMouseDrag)
	self:EnableMouseWheel(not not enableMouseWheel)
end

-- Event handler
---------------------------------------------------------------
function Bar:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function Bar:PLAYER_REGEN_ENABLED()
	self:FadeOut(self:GetAlpha())
end

function Bar:PLAYER_REGEN_DISABLED()
	self:FadeIn(self:GetAlpha())
end

function Bar:PLAYER_LOGIN()
	self:OnLoad(env.cfg)
end

function Bar:ADDON_LOADED(name)
	if name == _ then
		if not ConsolePort_BarSetup then
			ConsolePort_BarSetup = env:GetDefaultSettings()
		end
		env:LoadAssets()
		env:SetConfig(ConsolePort_BarSetup, false)
		self:UnregisterEvent('ADDON_LOADED')
		self.ADDON_LOADED = nil
	end
end

-- Script handlers
---------------------------------------------------------------
function Bar:OnMouseWheel(delta)
	if not InCombatLockdown() then
		local cfg = env.cfg
		if IsShiftKeyDown() then
			local newWidth = self:GetWidth() + ( delta * 10 )
			cfg.width = newWidth > BAR_MIN_WIDTH and newWidth or BAR_MIN_WIDTH
			self:SetWidth(cfg.width)
		else
			local newScale = self:GetScale() + ( delta * 0.1 )
			cfg.scale = Clamp(newScale, 0.1, BAR_MAX_SCALE)
			self:SetScale(cfg.scale)
		end
	end
end

function Bar:OnLoad(cfg, benign)
	local r, g, b = CPAPI.NormalizeColor(CPAPI.GetClassColor())
	env:SetConfig(cfg, false)
	self:SetScale(Clamp(cfg.scale or 1, 0.1, BAR_MAX_SCALE))

	-- Fade out of combat
	self:SetAttribute('hidesafe', cfg.hidebar)
	if cfg.hidebar then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		self:RegisterEvent('PLAYER_REGEN_DISABLED')
		self:FadeOut(self:GetAlpha())
	else
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')
		self:FadeIn(self:GetAlpha())
	end

	-- Bar vis driver
	local visDriver = '[petbattle][vehicleui][overridebar] hide; show'
	if cfg.combathide then
		visDriver = '[combat]' .. visDriver
	end

	RegisterStateDriver(Bar, 'visibility', visDriver)

	-- Pet driver
	if cfg.hidepet then
		UnregisterStateDriver(Bar.Pet, 'visibility')
		Bar.Pet:Hide()
	elseif cfg.combatpethide then
		RegisterStateDriver(Bar.Pet, 'visibility', '[pet,nocombat] show; hide')
	else
		RegisterStateDriver(Bar.Pet, 'visibility', '[pet] show; hide')
	end

	-- Show class tint line
	if cfg.showline then
		self.BG:Show()
		self.BottomLine:Show()
	else
		self.BG:Hide()
		self.BottomLine:Hide()
	end

	-- Set action bar art
	env:SetArtUnderlay(cfg.showart or cfg.flashart, cfg.flashart)

	-- Rainbow sine wave color script, cuz shiny
	env:SetRainbowScript(cfg.rainbow)

	-- Tint RGB for background textures and LED
	SetCVar('GamePadFactionColor', 0)
	if cfg.tintRGB then
		env:SetTintColor(unpack(cfg.tintRGB))
	else
		env:SetTintColor(r, g, b, 1)
	end

	-- Show 'the eye'
	self.Eye:SetShown(cfg.eye)

	-- Lock/unlock pet ring
	self.Pet:RegisterForDrag(not cfg.lockpet and 'LeftButton' or '')
	if cfg.disablepetfade then
		self.Pet:FadeIn()
	else
		self.Pet:FadeOut()
	end

	-- Lock/unlock bar
	self:ToggleMovable(not cfg.lock, cfg.mousewheel)

	cfg.layout = cfg.layout or env:GetDefaultButtonLayout()

	-- Configure individual buttons
	local layout = cfg.layout

	local swipeRGB = cfg.swipeRGB
	local borderRGB = cfg.borderRGB

	local hideIcons = cfg.hideIcons
	local hideModifiers = cfg.hideModifiers
	local classicBorders = cfg.classicBorders

	wipe(self.Buttons)
	local activeDevice = db('Gamepad/Active')

	if activeDevice then
		for binding in ConsolePort:GetBindings() do
			local positionData = layout[db.UIHandle:GetUIControlBinding(binding)]
			local isUsableBinding = activeDevice:IsButtonValidForBinding(binding)
			local cluster = Clusters:Get(binding)

			if not cluster and positionData and isUsableBinding then
				cluster = Clusters:Create(self, binding)
			end

			if cluster then
				if positionData and isUsableBinding then
					cluster:Show()
					cluster:SetPoint(unpack(positionData.point))
					if positionData.dir then
						cluster:UpdateOrientation(positionData.dir)
					end
					if positionData.size then
						cluster:SetSize(positionData.size)
					end
				else
					cluster:Hide()
				end

				cluster:ToggleIcon(not hideIcons)
				cluster:ToggleModifiers(not hideModifiers)
				cluster:SetClassicBorders(classicBorders)

				if swipeRGB then cluster:SetSwipeColor(unpack(swipeRGB))
				else cluster:SetSwipeColor(r, g, b, 1) end

				if borderRGB then cluster:SetBorderColor(unpack(borderRGB))
				else cluster:SetBorderColor(1, 1, 1, 1) end

				self.Buttons[#self.Buttons + 1] = cluster
			end
		end
	end

	self.WatchBarContainer:Hide() -- hide so it updates OnShow, if set.
	self.WatchBarContainer:SetShown(not cfg.hidewatchbars)

	-- Don't run this when updating simple cvars
	if not benign then
		Clusters:UpdateAllBindings(db.Gamepad:GetBindings(true))
		self:UpdateOverrides()
		-- states have been reparsed, set back to current state
		self:Execute([[
			control:ChildUpdate('state', self:GetAttribute('state'))
			self:RunAttribute('_onstate-page', self:GetAttribute('actionpage'))
		]])
		self:MoveMicroButtons()
	end

	-- Always show modifiers
	if cfg.showbuttons then
		self.Eye:SetAttribute('showbuttons', true)
		self:Execute([[
			control:ChildUpdate('hover', true)
		]])
	else
		self.Eye:SetAttribute('showbuttons', false)
		self:Execute([[
			control:ChildUpdate('hover', false)
		]])
	end

	local width = cfg.width or ( #self.Buttons > 10 and (10 * 110) + 55 or (#self.Buttons * 110) + 55 )
	self:SetSize(width, BAR_FIXED_HEIGHT)
end

db:RegisterSafeCallback('Gamepad/Active', function(self) self:OnLoad(env.cfg) end, Bar)
db:RegisterSafeCallback('OnActionBarConfigChanged', Bar.OnLoad, Bar)

Bar:SetScript('OnEvent', Bar.OnEvent)
Bar:SetScript('OnMouseWheel', Bar.OnMouseWheel)
for _, event in ipairs({
	'SPELLS_CHANGED',
	'PLAYER_LOGIN',
	'ADDON_LOADED',
	'PLAYER_TALENT_UPDATE',
}) do pcall(Bar.RegisterEvent, Bar, event) end

-- Registry
---------------------------------------------------------------
Bar.Buttons = {}
Bar.Elements = {}