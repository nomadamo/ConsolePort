local env = LibStub('RelaTable')(...)
--------------------------------------------------------
env.db    = ConsolePort:GetData()
env.Frame = ConsolePortBar;
env.libs  = { acb = LibStub('CPActionButton') };
env:Register('Data', {})
--------------------------------------------------------
local r, g, b = CPAPI.NormalizeColor(CPAPI.GetClassColor())

function env:GetDefaultButtonLayout(button)
	local layout = {
		---------
		PADDLEFT 	= {point = {'LEFT', 176, 56}, dir = 'left', size = 64},
		PADDRIGHT 	= {point = {'LEFT', 306, 56}, dir = 'right', size = 64},
		PADDUP 	    = {point = {'LEFT', 240, 100}, dir = 'up', size = 64},
		PADDDOWN 	= {point = {'LEFT', 240, 16}, dir = 'down', size = 64},
		---------
		PAD3 		= {point = {'RIGHT', -306, 56}, dir = 'left', size = 64},
		PAD2 		= {point = {'RIGHT', -176, 56}, dir = 'right', size = 64},
		PAD4 		= {point = {'RIGHT', -240, 100}, dir = 'up', size = 64},
		PAD1 		= {point = {'RIGHT', -240, 16}, dir = 'down', size = 64},
	}

	local handle = env.db.UIHandle;
	local T1, T2 = handle:GetUIControlBinding('T1'), handle:GetUIControlBinding('T2')
	local M1, M2 = handle:GetUIControlBinding('M1'), handle:GetUIControlBinding('M2')

	if M1 then layout[M1] = {point = {'LEFT', 456, 56}, dir = 'right', size = 64} end;
	if M2 then layout[M2] = {point = {'RIGHT', -456, 56}, dir = 'left', size = 64} end;
	if T1 then layout[T1] = {point = {'LEFT', 396, 16}, dir = 'down', size = 64} end;
	if T2 then layout[T2] = {point = {'RIGHT', -396, 16}, dir = 'down', size = 64} end;

	if button ~= nil then
		return layout[button]
	else
		return layout
	end
end

function env:GetOrthodoxButtonLayout()
	local layout = {
		---------
		PADDRIGHT = {dir = 'right', point = {'LEFT', 330, 9}, size = 64},
		PADDLEFT = {dir = 'left', point = {'LEFT', 80, 9}, size = 64},
		PADDDOWN = {dir = 'down', point = {'LEFT', 165, 9}, size = 64},
		PADDUP = {dir = 'up', point = {'LEFT', 250, 9}, size = 64},
		---------
		PAD2 = {dir = 'right', point = {'RIGHT', -80, 9}, size = 64},
		PAD3 = {dir = 'left', point = {'RIGHT', -330, 9}, size = 64},
		PAD1 = {dir = 'down', point = {'RIGHT', -250, 9}, size = 64},
		PAD4 = {dir = 'up', point = {'RIGHT', -165, 9}, size = 64},
	}

	local handle = env.db.UIHandle;
	local T1, T2 = handle:GetUIControlBinding('T1'), handle:GetUIControlBinding('T2')
	local M1, M2 = handle:GetUIControlBinding('M1'), handle:GetUIControlBinding('M2')

	if M1 then layout[M1] = {dir = 'up', point = {'LEFT', 405, 75}, size = 64} end;
	if M2 then layout[M2] = {dir = 'up', point = {'RIGHT', -405, 75}, size = 64} end;
	if T1 then layout[T1] = {dir = 'right', point = {'LEFT', 440, 9}, size = 64} end;
	if T2 then layout[T2] = {dir = 'left', point = {'RIGHT', -440, 9}, size = 64} end;

	return layout;
end

function env:GetPresets()
	return {
		Default = self:GetDefaultSettings(),
		Orthodox = {
			scale = 0.9,
			width = 1100,
			watchbars = true,
			showline = true,
			showbuttons = false,
			lock = true,
			layout = self:GetOrthodoxButtonLayout(),
		},
		Roleplay = {
			scale = 0.9,
			width = 1100,
			watchbars = true,
			showline = true,
			showart = true,
			showbuttons = false,
			lock = true,
			layout = self:GetDefaultButtonLayout(),
		},
	}
end

function env:GetUserPresets()
	local presets, copy = {}, env.db.table.copy;
	for character, data in env.db:For('Shared/Data') do
		if data.Bar and data.Bar.layout then
			presets[character] = copy(data.Bar)
		end
	end
	return presets;
end

function env:GetAllPresets()
	return env.db.table.merge(self:GetPresets(), self:GetUserPresets())
end

function env:GetRGBColorFor(element, default)
	local cfg = env.cfg or {}
	local defaultColors = {
		art 	= {1, 1, 1, 1},
		tint 	= {r, g, b, 1},
		border 	= {1, 1, 1, 1},
		swipe 	= {r, g, b, 1},
		exp 	= {r, g, b, 1},
	}
	if default then
		if defaultColors[element] then
			return unpack(defaultColors[element])
		end
	end
	local current = {
		art 	= cfg.artRGB or defaultColors.art,
		tint 	= cfg.tintRGB or defaultColors.tint,
		border 	= cfg.borderRGB or defaultColors.border,
		swipe 	= cfg.swipeRGB or defaultColors.swipe,
		exp 	= cfg.expRGB or defaultColors.exp,
	}
	if current[element] then
		return unpack(current[element])
	end
end

function env:GetDefaultSettings()
	return 	{
		scale = 0.9,
		width = 1100,
		watchbars = true,
		showline = true,
		lock = true,
		flashart = true,
		eye = true,
		showbuttons = false,
		layout = env:GetDefaultButtonLayout()
	}
end

function env:GetColorGradient(red, green, blue)
	local gBase = 0.15
	local gMulti = 1.2
	local startAlpha = 0.25
	local endAlpha = 0
	local gradient = {
		'VERTICAL',
		(red + gBase) * gMulti, (green + gBase) * gMulti, (blue + gBase) * gMulti, startAlpha,
		1 - (red + gBase) * gMulti, 1 - (green + gBase) * gMulti, 1 - (blue + gBase) * gMulti, endAlpha,
	}
	return unpack(gradient)
end

function env:GetBooleanSettings() return {
	{	name = 'Width/scale on mouse wheel';
		cvar = 'mousewheel';
		desc = 'Allows you to scroll on the action bar to adjust its proportions.';
		note = 'Hold Shift to adjust width, otherwise scale.';
	};
	---------------------------------------
	{	name = 'Visibility & Lock' };
	{	name = 'Lock action bar';
		cvar = 'lock';
		desc = 'Lock/unlock action bar, allowing it to be moved with the mouse.';
	};
	{	name = 'Hide in combat';
		cvar = 'combathide';
		desc = 'Hide action bar in combat.';
		note = 'Only for the truly insane.';
	};
	{	name = 'Fade out of combat';
		cvar = 'hidebar';
		desc = 'Fades out the action bar while not in combat.';
		note = 'The action bar will become visible if you bring your cursor over it.';
	};
	{	name = 'Disable drag and drop';
		cvar = 'disablednd';
		desc = 'Disables dragging and dropping actions using your mouse cursor.';
	};
	{	name = 'Always show all buttons';
		cvar = 'showbuttons';
		desc = 'Shows the entire button cluster at all times, not just abilities on cooldown.';
	};
	---------------------------------------
	{	name = 'Pet Ring' };
	{	name = 'Lock pet ring';
		cvar = 'lockpet';
		desc = 'Lock/unlock pet ring, allowing it to be moved with the mouse.';
	};
	{	name = 'Disable pet ring';
		cvar = 'hidepet';
		desc = 'Disables the pet ring entirely.';
	};
	{	name = 'Hide pet ring in combat';
		cvar = 'combatpethide';
		desc = 'Hide pet ring in combat.';
	};
	{	name = 'Always show all buttons';
		cvar = 'disablepetfade';
		desc = 'Shows the entire pet ring cluster at all times, not just abilities on cooldown.';
	};
	---------------------------------------
	{	name = 'Display' };
	{	name = 'The Eye';
		cvar = 'eye';
		desc = 'Shows an "eye" in the middle of your action bar, to quickly toggle between show/hide all buttons.';
		note = 'The Eye can be used to train your gameplay performance.';
	};
	{	name = 'Disable watch bars';
		cvar = 'hidewatchbars';
		desc = 'Disables watch bars at the bottom of the action bar.';
		note = 'Disables all tracking of experience, honor, reputation and artifacts.';
	};
	{	name = 'Always show watch bars';
		cvar = 'watchbars';
		desc = 'When enabled, shows watch bars at all times. When disabled, shows them on mouse over.';
	};
	{	name = 'Hide main button icons';
		cvar = 'hideIcons';
		desc = 'Hide binding icons on all large buttons.';
	};
	{	name = 'Hide modifier icons';
		cvar = 'hideModifiers';
		desc = 'Hide binding icons on all small buttons.';
	};
	{	name = 'Use beveled borders';
		cvar = 'classicBorders';
		desc = 'Use the classic button border texture.';
	};
	{ 	name = 'Disable micro menu modifications';
		cvar = 'disablemicromenu';
		desc = 'Disables micro menu modifications.';
		note = 'Check this if you have another addon customizing the micro menu.';
	};
	---------------------------------------
	{	name = 'Cast Bar' };
	{	name = 'Show default cast bar';
		cvar = 'defaultCastBar';
		desc = 'Shows the default cast bar, adjusted to the action bar position.';
	};
	{	name = 'Disable cast bar modification';
		cvar = 'disableCastBarHook';
		desc = 'Disables any modifications to the cast bar, including position.';
		note = 'This may fix compatibility issues with other addons modifying the cast bar.';
	};
	---------------------------------------
	{	name = 'Artwork' };
	{	name = 'Show class art underlay';
		cvar = 'showart';
		desc = 'Shows a class-based artpiece under your button clusters, to use as anchoring reference.';
	};
	{	name = 'Blend class art underlay';
		cvar = 'blendart';
		desc = 'Sets class art underlay to blend colors with the background, resulting in a brighter, less opaque texture.';
	};
	{	name = 'Flash art underlay on proc';
		cvar = 'flashart';
		desc = 'Flashes the art underlay whenever a spell procs and starts glowing.';
	};
	{	name = 'Smaller art underlay';
		cvar = 'smallart';
		desc = 'Reduces the size of the class art underlay.';
	};
	{	name = 'Show color tint';
		cvar = 'showline';
		desc = 'Shows a subtle tint, anchored to the top of the watch bars.';
	};
	{	name = 'RGB Gaming God';
		cvar = 'rainbow';
		desc = 'Behold the might of my personal computer, you dirty console peasant. Do you really have enough buttons on that thing to match me?';
		note = ('|T%s:64:128:0|t'):format([[Interface\AddOns\ConsolePort_Config\Assets\master.blp]]);
	};
} end

function env:GetNumberSettings() return {
	---------------------------------------
	{	name = 'Size' };
	{	name = 'Width';
		cvar = 'width';
		desc = 'Changes the overall action bar width.';
		note = 'Affects button placement.';
		step = 10;
	};
	{	name = 'Scale';
		cvar = 'scale';
		desc = 'Changes the overall action bar scale.';
		note = 'Affects button size - individual size is multiplied by scale.';
		step = 0.05;
	};
} end

function env:GetColorSettings() return {
	---------------------------------------
	{	name = 'Colors' };
	{	name = 'Border';
		cvar = 'borderRGB';
		desc = 'Changes the color of your button borders.';
		note = 'Right click to reset to default color.';
	};
	{	name = 'Cooldown';
		cvar = 'swipeRGB';
		desc = 'Changes the color of your cooldown graphics.';
		note = 'Right click to reset to class color.';
	};
	{	name = 'Tint';
		cvar = 'tintRGB';
		desc = 'Changes the color of the tint texture above experience bars.';
		note = 'Right click to reset to class color.';
	};
	{	name = 'Experience Bars';
		cvar = 'expRGB';
		desc = 'Changes the preferred color of your experience bars.';
		note = 'Right click to reset to class color.';
	};
	{	name = 'Artwork';
		cvar = 'artRGB';
		desc = 'Changes the color of class-based background artwork.';
		note = 'Right click to reset to default color.';
	};
} end