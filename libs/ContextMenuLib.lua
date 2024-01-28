-- Used to create the name of the context menu frame if it doesn't have a parent at time of Initialization.
local addonName = ...

local baseItemIndent = 20
local subItemIndent = baseItemIndent + 10
local itemEndMargin = 4

local maxHeight = GetScreenHeight()

ContextMenuLibMixin = {}

local contextMenuItems = {}

local ContextMenuItemList = CreateFromMixins(CallbackRegistryMixin)
ContextMenuItemList:GenerateCallbackEvents(
    {
        "OnClick",
        "OnEnter",
        "OnLeave"
    }
)

function ContextMenuItemList:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:SetScript("OnClick", self.OnClick)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
end

function ContextMenuItemList:OnClick(button)
    self:TriggerEvent("OnClick", self, button)
end

function ContextMenuItemList:OnEnter(button)
    self:TriggerEvent("OnEnter", self, button)
end

function ContextMenuItemList:OnLeave(button)
    self:TriggerEvent("OnLeave", self, button)
end

function ContextMenuItemList:Init(data)
    if (data.isHeader) then
        if (data.isCollapsed) then
            self.expandIcon:SetTexture(130838)
        else
            self.expandIcon:SetTexture(130821)
        end
        self.Text:SetText(data.name)
    else
        local frame = self.itemFrame
        local indent = baseItemIndent
        if (data.icon) then
            if (C_Texture.GetAtlasInfo(data.icon)) then
                frame.Icon:SetAtlas(data.icon);
            else
                frame.Icon:SetTexture(data.icon);
            end
            frame.Icon:Show()
            indent = indent + 16
        else
            frame.Icon:Hide()
        end
        if (not data.isCheckbox) then
            frame.Checkbox:Hide()
            frame.Checkbox_Check:Hide()
        else
            frame.Checkbox:Show()
            if (data.isChecked) then
                frame.Checkbox_Check:Show()
            else
                frame.Checkbox_Check:Hide()
            end
        end
        local text = data.name
        if(data.color) then
            text = "\124c" .. data.color .. data.name .. "\124r"
        end

        frame.Text:SetText(text)
        frame.Text:SetPoint("TOPLEFT", indent, 0)
    end
end

local ContextMenu = {}

function ContextMenu:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self.ScrollView = CreateScrollBoxListLinearView()
    self.ScrollView:SetDataProvider(CreateDataProvider())
    self.ScrollView:SetElementFactory(function(factory, data)
        if (data.isHeader) then
            factory("CML_MenuHeader", function(button, data)
                self:OnElementInitialize(button, data)
            end)
        else
            if (data.isSubitem) then
                factory("CML_SubMenuItem", function(button, data)
                    self:OnElementInitialize(button, data)
                end)
            else
                factory("CML_MenuItem", function(button, data)
                    self:OnElementInitialize(button, data)
                end)
            end
        end
    end)
    self.ScrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self))

    self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
    self.ScrollBox:SetPoint("TOPLEFT", 10, -28)
    self.ScrollBox:SetPoint("BOTTOMRIGHT", -20, 5)

    self.ScrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
    self.ScrollBar:SetPoint("TOPLEFT", self.ScrollBox, "TOPRIGHT", 8, 0)
    self.ScrollBar:SetPoint("BOTTOMLEFT", self.ScrollBox, "BOTTOMRIGHT", 8, 0)
    self.ScrollBar:SetScale(.75)

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView)
end

function ContextMenu:OnElementInitialize(element, data)
    if (not element.OnLoad) then
        Mixin(element, ContextMenuItemList)
        element:OnLoad()
    end

    element:Init(data)
    element:RegisterCallback("OnClick", self.OnElementClicked, self)
    element:RegisterCallback("OnEnter", self.OnElementEnter, self)
    element:RegisterCallback("OnLeave", self.OnElementLeave, self)
end

function ContextMenu:OnElementReset(element)
    element:UnregisterCallback("OnClick", self)
    element:UnregisterCallback("OnEnter", self)
    element:UnregisterCallback("OnLeave", self)
end

function ContextMenu:OnElementClicked(element, button)
    local data = element:GetData()
    if (button == "LeftButton") then
        if (data.isHeader) then
            contextMenuItems[data.key].header.isCollapsed = not contextMenuItems[data.key].header.isCollapsed
            self:RefreshView()
        else
            if(data.func) then
                data.func()
            end
            if(data.isCheckbox) then
                if(data.closeOnClick) then
                    self:Hide()
                else
                    data.isChecked = not data.isChecked
                    self:RefreshView()
                end
            else
                self:Hide()
            end
        end
    end
end

function ContextMenu:OnElementEnter(element)
    local data = element:GetData()
    if (data.tooltip) then
        GameTooltip:SetOwner(element, "ANCHOR_BOTTOMRIGHT", 25, 20)
        if (data.tooltip.title) then
            GameTooltip_SetTitle(GameTooltip, data.tooltip.title, NORMAL_FONT_COLOR)
        end
        for k, v in pairs(data.tooltip.lines) do
            local type
            if (v.type == "HIGHTLIGHT") then
                GameTooltip_AddHighlightLine(GameTooltip, v.text)
            elseif (v.type == "INSTRUCTION") then
                GameTooltip_AddInstructionLine(GameTooltip, v.text)
            elseif (v.type == "ERROR") then
                GameTooltip_AddErrorLine(GameTooltip, v.text)
            else
                GameTooltip_AddNormalLine(GameTooltip, v.text)
            end
        end
        GameTooltip:Show()
    end
end

function ContextMenu:OnElementLeave(element)
    GameTooltip:Hide()
end

function ContextMenu:RefreshView()
    if (contextMenuItems ~= nil) then
        local data = CreateDataProvider()
        for key, item in pairs(contextMenuItems) do
            local excludeItem = false
            if (item.header) then
                if (not item.header.name) then
                    error("Menu item header name required", 2)
                end
                data:InsertTable({
                    {
                        isHeader = true,
                        isCollapsed = item.header.isCollapsed,
                        name = item.header.name,
                        key = key
                    }
                })
                if (not item.header.isCollapsed) then
                    for _, subItem in pairs(item.header.menuItems) do
                        if (subItem.header) then
                            error("Can not have a header in a sub menu", 2)
                        end
                        if (not subItem.name) then
                            error("Menu item name required in sub menu", 2)
                        end
                        data:InsertTable({ subItem })
                    end
                end
            else
                if (not item.name) then
                    error("Menu item name required", 2)
                end
                data:InsertTable({ item })
            end
        end
        self.ScrollView:SetDataProvider(data, ScrollBoxConstants.RetainScrollPosition)

        local frameHeight = self.ScrollView:GetExtent() + 33
        if(frameHeight > maxHeight) then
            frameHeight = maxHeight
        end
        if(frameHeight < 65) then --Minimum height before frame glitches
            frameHeight = 65
        end
        self:SetHeight(frameHeight)

        --Next line adds the DataProvider to a global variale for easy access in WoW.
        SampleContextData = self.ScrollView.dataProvider.collection
    end
end

--Opens the ContextMenu using a table with information that helps build and displays the frame
-- Example of table
--[[
    local contextInfo = {
        --The title to display
        title = "Context Menu Title",

        -- Maximum height before scrolling
        maximumHeight = 200,

        -- Maximum width of frame (text after this width with truncate)
        maximumWidth = 400,

        -- parent frame of context menu. required!
        parent = self (in this case, self is a button)

        -- menu items
        menuItems = {  -- Any settings that are not required can be omitted during creation of table
            {
                -- Name of the first item, required!
                name = "First item",

                -- Icon settings (leave out for no icon)
                icon = 134400, -- (can be either normal or atlas)

                -- Color of menu item, works for both item and headers.
                color = "FFFF00FF" -- (uses hex: AARRGGBB, no has)

                -- Sets if a checkbox will be drawn (does not work with header) Checkbox will be before the icon if one is set
                isCheckbox = false

                -- Sets if the checkbox is marked or not (only works if isCheckbox is set to true)
                isChecked = false

                -- Close menu when checkmark is clicked
                closeOnClick = true

                -- tooltip settings as follows:
                tooltip = {
                    -- tooltip title
                    title = "First!",

                    -- lines in tooltip
                    lines {
                        --First line will just have normal text
                        {
                            "First Line"
                        },
                        -- setting types on lines give other colors:
                        -- "HIGHTLIGHT" = white text, "INSTRUCTION" = green text, "ERROR" = red text, "DISABLED" = gray text
                        -- "NORMAL" Gold font (default)
                        {
                            "Second Line",
                            type = "INSTRUCTION"
                        }
                    }
                }

                -- this is the function when the item is clicked
                func = function()
                    print("Clicked me")
                end
            }, -- To create a header with sub items, add another table with header as the information
            {
                header = {
                    name = "First Header",
                    menuItems = {
                        --All items under this header (same as above) CANNOT have another header!
                    }
                }
            }
        }
    }
]]

function ContextMenu:Open(contextInfo)
    self:SetTitle(contextInfo.title)
    if(contextInfo.maximumHeight) then
        if(maxHeight >= contextInfo.maximumHeight) then
            maxHeight = contextInfo.maximumHeight
        end
    end
    if (not contextInfo.parent) then
        error("contextInfo.parent (expected table, got nil)", 2)
    end
    self:SetParent(contextInfo.parent)
    self:SetPoint("TOPLEFT", contextInfo.parent, "TOPRIGHT", 10, 0)
    self:SetFrameStrata("DIALOG")
    contextMenuItems = contextInfo.menuItems
    local longestText = 0
    -- Set some base variables for menuItems
    for k, v in pairs(contextMenuItems) do
        local checkLength = 0
        if (v.header) then
            self.TextCheck:SetText(v.header.name)
            if (self.TextCheck:GetStringWidth() + 40 > longestText) then
                longestText = self.TextCheck:GetStringWidth() + 40 --account for header margins
            end
            v.header.isCollapsed = true
            for _, si in pairs(v.header.menuItems) do
                self.TextCheck:SetText(si.name)
                local addition = subItemIndent + itemEndMargin
                if (si.icon) then
                    addition = addition + 16
                end
                if (self.TextCheck:GetStringWidth() + addition > longestText) then
                    longestText = self.TextCheck:GetStringWidth() + addition --account for margin and icon if present
                end
                si.isSubitem = true
            end
        else
            self.TextCheck:SetText(v.name)
            local addition = baseItemIndent + itemEndMargin
            if (v.icon) then
                addition = addition + 16
            end
            if (self.TextCheck:GetStringWidth() + addition > longestText) then
                longestText = self.TextCheck:GetStringWidth() + addition --account for margin and icon if present
            end
        end
    end
    self:RefreshView()



    local frameWidth = longestText + 38
    --next check frame title width as well 54
    local fTitleWidth = self.TitleContainer.TitleText:GetStringWidth() + 54
    if (fTitleWidth > longestText + 38) then
        frameWidth = fTitleWidth
    end


    --check if frame is either wide enough for item texts or at maximumWidth
    if (contextInfo.maximumWidth) then
        if (longestText + 38 > contextInfo.maximumWidth) then
            frameWidth = contextInfo.maximumWidth
        end
    end

    -- Finally check minimum width
    -- Context Menu is using DefaultPanelFlatTemplate. Due to an issue with this frame, the minimum width MUST BE 138
    if (frameWidth < 138) then
        frameWidth = 138
    end
    self:SetWidth(frameWidth) --Set size based on content with maximumWidth

    self:Show()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function ContextMenuLibMixin:Init()                                                                      --Initialize the context menu frame
    self.ContextMenu = Mixin(CreateFrame("Frame", nil, UIParent, "DefaultPanelFlatTemplate"), ContextMenu)
    self.ContextMenu.TextCheck = self.ContextMenu:CreateFontString(nil, "BACKGROUND", "ContextMenuFont") -- used to calculate the width of the menu
    self.ContextMenu:SetClampedToScreen(true)
    self.ContextMenu:SetFrameStrata("DIALOG")
    self.ContextMenu:OnLoad()
    self.ContextMenu:Hide()
    self.ContextMenu:SetScript("OnHide", function(self)
        self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
    end)
    self.ContextMenu:SetScript("OnEvent", function(self, event)
        if (event == "GLOBAL_MOUSE_DOWN") then
            if (not self:IsMouseOver()) then
                self:Hide()
            end
        end
    end)
end

function ContextMenuLibMixin:ShowContextMenu(contextInfo)
    self.ContextMenu:Open(contextInfo)
end
