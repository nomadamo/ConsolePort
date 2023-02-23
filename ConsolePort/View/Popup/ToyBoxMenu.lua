---------------------------------------------------------------
-- ToyBoxMenu.lua: Popup menu for managing Toys
---------------------------------------------------------------
local _, db, L = ...; L = db.Locale;
local ToyBoxMenu = db:Register('ToyBoxMenu', CPAPI.EventHandler(ConsolePortToyBoxMenu))
---------------------------------------------------------------
local TOYBOX_MENU_SIZE = 440;
local TOYBOX_MAP_BAR_SIZE = 600;
local TOYBOX_MAP_BAR_IDS = db.Actionbar.Pages;
---------------------------------------------------------------

function ToyBoxMenu:SetToy(toyID)
	self:SetDisplayToy(toyID)
	self:SetWidth(TOYBOX_MENU_SIZE)
	self:SetTooltip()
	self:SetCommands()
	self:FixHeight()
	self:Show()
	self:RedirectCursor()
end

function ToyBoxMenu:SetDisplayToy(toyID)
	self:SetItemID(toyID)
	if self:IsItemEmpty() then
		return self:Hide()
	end
	self.Icon:SetTexture(self:GetToyTexture())
	self.Name:SetText(self:GetToyName())
end

function ToyBoxMenu:FixHeight()
	local lastItem = self:GetObjectByIndex(self:GetNumActive())
	if lastItem then
		local height = self:GetHeight() or 0
		local bottom = self:GetBottom() or 0
		local anchor = lastItem:GetBottom() or 0
		self:SetHeight(height + bottom - anchor + 16)
	end
end

function ToyBoxMenu:RedirectCursor()
	self.returnToNode = self.returnToNode or ConsolePortCursor:GetCurrentNode()
	ConsolePortCursor:SetCurrentNode(self:GetObjectByIndex(1))
end

function ToyBoxMenu:ReturnCursor()
	if self.returnToNode then
		ConsolePortCursor:SetCurrentNode(self.returnToNode)
		self.returnToNode = nil
	end
end

---------------------------------------------------------------
-- Add toy commands
---------------------------------------------------------------
function ToyBoxMenu:SetCommands()
	self:ReleaseAll()

	self:AddUtilityRingCommand()
	-- self:AddCommand(L'Pick up', 'Pickup')
end

---------------------------------------------------------------
-- Commands
---------------------------------------------------------------
function ToyBoxMenu:Pickup()
	C_ToyBox.PickupToyBoxItem(self:GetItem())
	self:Hide()
end

function ToyBoxMenu:AddUtilityRingCommand()
	local link = C_ToyBox.GetToyLink()
	local action = {
		type  = 'item';
		item = link;
		link  = link;
	};

	if db.Utility:SetPendingAction(1, action) then
		self:AddCommand(L'Add to Utility Ring', 'RingBind')
	else
		local _, existingIndex = db.Utility:IsUniqueAction(1, action)
		if existingIndex then
			db.Utility:SetPendingRemove(1, action)
			self:AddCommand(L'Remove from Utility Ring', 'RingClear')
		end
	end
end

function ToyBoxMenu:RingBind()
	if db.Utility:HasPendingAction() then
		db.Utility:PostPendingAction()
	end
	self:Hide()
end

ToyBoxMenu.RingClear = ToyBoxMenu.RingBind;

function ToyBoxMenu:AddCommand(text, command, data)
	local widget, newObj = self:Acquire(self:GetNumActive() + 1)
	local anchor = self:GetObjectByIndex(self:GetNumActive() - 1)

	if newObj then
		widget:SetScript('OnClick', widget.OnClick)
	end

	widget:SetCommand(text, command, data)
	widget:SetPoint('TOPLEFT', anchor or self.Tooltip, 'BOTTOMLEFT', anchor and 0 or 8, anchor and 0 or -16)
	widget:Show()
end

---------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------
ToyBoxMenu.Tooltip = ConsolePortPopupMenuTooltip;

function ToyBoxMenu:SetTooltip()
	local tooltip = self.Tooltip
	tooltip:SetParent(self)
	tooltip:SetOwner(self, 'ANCHOR_NONE')
	tooltip:SetToyByItemID(select(1,self:GetToyInfo()))
	tooltip:Show()
	tooltip:ClearAllPoints()
	tooltip:SetPoint('TOPLEFT', 80, -16)
end

function ToyBoxMenu:SetDescription(text)
	local tooltip = self.Tooltip
	tooltip:SetParent(self)
	tooltip:SetOwner(self, 'ANCHOR_NONE')
	tooltip:SetText(' ')
	tooltip:AddLine(text, 1, 1, 1)
	tooltip:Show()
	tooltip:ClearAllPoints()
	tooltip:SetPoint('TOPLEFT', 80, -16)
end

function ToyBoxMenu:ClearTooltip()
	self.Tooltip:Hide()
end

---------------------------------------------------------------
-- Catcher
---------------------------------------------------------------
ToyBoxMenu.CatchBinding = CreateFrame('Button', nil, ToyBoxMenu,
	(CPAPI.IsRetailVersion and 'SharedButtonLargeTemplate' or 'UIPanelButtonTemplate')..',CPPopupBindingCatchButtonTemplate')

local NO_BINDING_TEXT, SET_BINDING_TEXT = [[ 
|cFFFFFF00Set Binding|r

%s in %s, does not have a binding assigned to it.

Press a button combination to select a new binding for this slot.

]], [[ 
|cFFFFFF00Set Binding|r

Press a button combination to select a new binding for %s.

]]

---------------------------------------------------------------
-- API
---------------------------------------------------------------
ToyBoxMenu.GetToyLink = ToyBoxMenu.GetToyLink or function(self)
	return (GetToyLink(select(1,self:GetToyInfo())));
end

ToyBoxMenu.GetToyName = ToyBoxMenu.GetToyName or function(self)
	return (GetToyName(select(1,self:GetToyInfo())));
end

ToyBoxMenu.GetToyTexture = ToyBoxMenu.GetToyTexture or function(self)
	return (GetToyTexture(select(1,self:GetToyInfo())));
end

---------------------------------------------------------------
-- Handlers and init
---------------------------------------------------------------
function ToyBoxMenu:OnHide()
	self:ReturnCursor()

	local handle = db.UIHandle;
	if handle:IsHintFocus(self) then
		handle:HideHintBar()
	end
	handle:ClearHintsForFrame(self)
end

---------------------------------------------------------------
ToyBoxMenu:SetScript('OnHide', ToyBoxMenu.OnHide)
Mixin(ToyBoxMenu, CPIndexPoolMixin):OnLoad()
ToyBoxMenu:CreateFramePool('Button', 'CPPopupButtonTemplate', db.PopupMenuButton)
ToyBoxMenu.ActionBarText = CreateFontStringPool(ToyBoxMenu, 'ARTWORK', nil, 'CPSmallFont')
db.Stack:AddFrame(ToyBoxMenu)