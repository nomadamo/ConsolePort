local _, env, db = ...; db = env.db;
---------------------------------------------------------------
-- Set up action bar
---------------------------------------------------------------
local Bar = Mixin(env.Frame, CPAPI.SecureEnvironmentMixin)

Bar:SetFrameRef('Cursor', ConsolePortRaidCursor)
Bar:SetFrameRef('Mouse', ConsolePortInteract)

Bar:Execute([[
	bindings = newtable()
	bar = self
	cursor = self:GetFrameRef('Cursor')
	mouse  = self:GetFrameRef('Mouse')
]])

---------------------------------------------------------------
-- Override bindings
---------------------------------------------------------------
function Bar:UnregisterOverrides()
	self:Execute([[
		bindings = wipe(bindings)
		self:ClearBindings()
	]])
end

function Bar:UpdateOverrides()
	self:Execute(self:GetAttribute('UpdateOverrides'))
end

function Bar:RegisterOverride(key, button)
	self:Execute(format([[
		bindings['%s'] = '%s'
	]], key, button))
end

function Bar:OnOverrideSet(key)
	db.Input:HandleConflict(self, false, key)
end

function Bar:OnNewBindings(bindings)
	self:UnregisterOverrides()
	env:TriggerEvent('OnNewBindings', bindings)
	self:UpdateOverrides()
end

db:RegisterSafeCallback('OnNewBindings', Bar.OnNewBindings, Bar)
db.Pager:RegisterHeader(Bar, true)


---------------------------------------------------------------
-- Secure functions
---------------------------------------------------------------
Bar:CreateEnvironment({
	_onhide = [[
		self:ClearBindings()
	]];
	_onshow = [[
		self::ApplyBindings()
		if PlayerInCombat() or ( not self:GetAttribute('hidesafe') ) then
			self:CallMethod('FadeIn')
		end
		mouse::OnBindingsChanged()
	]];
	ApplyBindings = [[
		for key, button in pairs(bindings) do
			self:SetBindingClick(false, key, button, 'ControllerInput')
			self:CallMethod('OnOverrideSet', key)
		end
	]];
	UpdateOverrides = [[
		self::ApplyBindings()
		local state = self:GetAttribute('state') or '';
		self:SetAttribute('state', state)
		control:ChildUpdate('state', state)
		mouse::OnBindingsChanged()
	]];
})

---------------------------------------------------------------
-- State drivers
---------------------------------------------------------------
function Bar:ConfigureStates()
	-- Configure modifiers
	-- Generate a string of drivers based on the currently active modifiers
	local drivers = {};
	for modCombo in db.table.mpairs(db('Gamepad/Index/Modifier/Active')) do
		local insert = {};
		for mod in modCombo:gmatch('%u+') do
			tinsert(insert, ('mod:%s'):format(mod):lower())
		end
		-- Insert in the opposite order so complex combos end up first
		tinsert(drivers, 1, (('[%s] %s'):format(table.concat(insert, ','), modCombo)))
	end
	self:SetAttribute('_onstate-modifier', [[
		self:SetAttribute('state', newstate)
		control:ChildUpdate('state', newstate)
		cursor:RunAttribute('ActionPageChanged')
	]])
	RegisterStateDriver(self, 'modifier', table.concat(drivers, ';'))


	-- Configure action page handling
	local now, driver, response = ConsolePort:GetActionPageDriver()
	self:SetAttribute('actionpage', now)
	self:SetAttribute('_onstate-page', response .. [[
		self:SetAttribute('actionpage', newstate)
		control:ChildUpdate('actionpage', newstate)
	]])
	RegisterStateDriver(self, 'page', driver)
end

Bar:ConfigureStates()
db:RegisterSafeCallbacks(Bar.ConfigureStates, Bar,
	'Gamepad/Active',
	'actionPageCondition',
	'actionPageResponse'
);