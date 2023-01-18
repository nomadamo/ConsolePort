local _, env = ...;
--------------------------------------------------------
do -- Default replacement icons for regular bindings
--------------------------------------------------------
	local function click(str)  return ('CLICK ConsolePort%s:LeftButton'):format(str) end;
	local function custom(str) return ([[Interface\AddOns\ConsolePort_Bar\Textures\Icons\%s]]):format(str) end; 
	local function client(str) return ([[Interface\Icons\%s]]):format(str) end;
	local isRetail = CPAPI.IsRetailVersion;

	env.Data.Icons = {
		------------------------------------------------
		JUMP                        = custom('Jump'),
		TOGGLERUN                   = custom('Run'),
		OPENALLBAGS                 = custom('Bags'),
		TOGGLEGAMEMENU              = custom('Menu'),
		TOGGLEWORLDMAP              = custom('Map'),
		------------------------------------------------
		INTERACTTARGET              = custom('Target'),
		------------------------------------------------
		TARGETNEARESTENEMY          = custom('Target'),
		TARGETPREVIOUSENEMY         = custom('Target'),
		TARGETSCANENEMY             = custom('Target'),
		TARGETNEARESTFRIEND         = custom('Target'),
		TARGETPREVIOUSFRIEND        = custom('Target'),
		TARGETNEARESTENEMYPLAYER    = custom('Target'),
		TARGETPREVIOUSENEMYPLAYER   = custom('Target'),
		TARGETNEARESTFRIENDPLAYER   = custom('Target'),
		TARGETPREVIOUSFRIENDPLAYER  = custom('Target'),
		------------------------------------------------
		TARGETPARTYMEMBER1          = isRetail and client('Achievement_PVP_A_01'),
		TARGETPARTYMEMBER2          = isRetail and client('Achievement_PVP_A_02'),
		TARGETPARTYMEMBER3          = isRetail and client('Achievement_PVP_A_03'),
		TARGETPARTYMEMBER4          = isRetail and client('Achievement_PVP_A_04'),
		TARGETSELF                  = isRetail and client('Achievement_PVP_A_05'),
		TARGETPET                   = client('Spell_Hunter_AspectOfTheHawk'),
		------------------------------------------------
		ATTACKTARGET                = client('Ability_SteelMelee'),
		STARTATTACK                 = client('Ability_SteelMelee'),
		PETATTACK                   = client('ABILITY_HUNTER_INVIGERATION'),
		FOCUSTARGET                 = client('Ability_Hunter_MasterMarksman'),
		------------------------------------------------
		[click('FocusButton')]      = client('VAS_RaceChange'),
		[click('EasyMotionButton')] = custom('Group'),
		[click('RaidCursorToggle')] = custom('Group'),
		[click('RaidCursorFocus')]  = custom('Group'),
		[click('RaidCursorTarget')] = custom('Group'),
		[click('UtilityToggle')]    = custom('Ring'),
		------------------------------------------------
	}

	function env:GetBindingIcon(binding)
		return env('Data/Icons/'..binding)
	end
end

--------------------------------------------------------
do -- Class art
--------------------------------------------------------
	local function px(i) return {0, 1, (( i - 1 ) * 256 ) / 1024, ( i * 256 ) / 1024 } end;
	local function id(i) return [[Interface\AddOns\ConsolePort_Bar\Textures\Covers\]]..i end;

	env.Data.ClassArt = {
		WARRIOR 	= {1, 1};
		PALADIN 	= {1, 2};
		DRUID 		= {1, 3};
		DEATHKNIGHT = {1, 4};
		----------------------------
		MAGE 		= {2, 1};
		HUNTER 		= {2, 2};
		ROGUE 		= {2, 3};
		WARLOCK 	= {2, 4};
		----------------------------
		SHAMAN 		= {3, 1};
		PRIEST 		= {3, 2};
		DEMONHUNTER = {3, 3};
		MONK 		= {3, 4};
	}

	function env:GetCover(class) class = class or CPAPI.GetClassFile();
		local info = env('Data/ClassArt/'..class)
		if info then
			local file, index = unpack(info)
			return id(file), px(index);
		end
	end
end

function env:SetArtUnderlay(enabled, flashOnProc)
	local cfg = env.cfg
	local bar = env.Frame;
	if enabled then
		local art, coords = self:GetCover()
		if art and coords then
			local artScale = cfg.smallart and .75 or 1
			bar.CoverArt:SetTexture(art)
			bar.CoverArt:SetTexCoord(unpack(coords))
			bar.CoverArt:SetVertexColor(unpack(cfg.artRGB or {1,1,1}))
			bar.CoverArt:SetBlendMode(cfg.blendart and 'ADD' or 'BLEND')
			bar.CoverArt:SetSize(768 * artScale, 192 * artScale)
			if cfg.showart then
				bar.CoverArt:Show()
			else
				bar.CoverArt:Hide()
			end
		end
	else
		bar.CoverArt:SetTexture(nil)
		bar.CoverArt:Hide()
	end
	bar.CoverArt.flashOnProc = flashOnProc;
end

--------------------------------------------------------
-- Colors
--------------------------------------------------------
function env:SetRainbowScript(on)
	if on then
		local t, i, p, c, w, m = 0, 0, 0, 128, 127, 180
		local hz = (math.pi*2) / m;
		local r, g, b;
		return self.Frame:SetScript('OnUpdate', function(_, e)
			t = t + e;
			if t > 0.1 then
				i = i + 1;
				r = (math.sin((hz * i) + 0 + p) * w + c) / 255;
				g = (math.sin((hz * i) + 2 + p) * w + c) / 255;
				b = (math.sin((hz * i) + 4 + p) * w + c) / 255;
				if i > m then
					i = i - m;
				end
				t = 0;
				self:SetTintColor(r, g, b, 1)
			end
		end)
	end
	self.Frame:SetScript('OnUpdate', nil)
end

--------------------------------------------------------
do -- Tint color
--------------------------------------------------------
	local a, r, g, b = 1, CPAPI.NormalizeColor(CPAPI.GetClassColor());
	local color = CreateColor(); color:SetRGBA(r, g, b, a);

	function env:SetTintColor(r, g, b, a) a = a or 1;
		color:SetRGBA(r, g, b, a)
		local bar, castBar = env.Frame, CastingBarFrame;
		local buttons = env.libs.registry;
		if castBar then
			castBar:SetStatusBarColor(r, g, b)
		end
		bar.WatchBarContainer:SetMainBarColor(r, g, b)
		CPAPI.SetGradient(bar.BG, self:GetColorGradient(r, g, b))
		bar.BottomLine:SetVertexColor(r, g, b, a)
		for _, button in pairs(buttons) do
			button:SetSwipeColor(r, g, b, a)
		end
		if C_GamePad.SetLedColor then
			C_GamePad.SetLedColor(color)
		end
	end
end

function env:LoadAssets()
	ConsolePort_BarIcons = ConsolePort_BarIcons or {};
	CPAPI.Proxy(ConsolePort_BarIcons, env('Data/Icons'))
	env('Data/Icons', ConsolePort_BarIcons)
end
