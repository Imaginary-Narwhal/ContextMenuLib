local Sample = {}


Sample.Frame = CreateFrame("Frame", "SampleFrame", UIParent, "ButtonFrameTemplate")
ButtonFrameTemplate_HidePortrait(Sample.Frame)

-- Next line adds the local table to the global for easy access in WoW.
SampleContextMenu = Sample

-- Create a context menu mixin. You can create one to reuse over and over, or can create multiples
-- local ContextMenu = CreateFromMixins(ContextMenuLibMixin) --Create the context menu locally or
Mixin(Sample.Frame, ContextMenuLibMixin) --Mix it into a frame

Sample.Frame:Init()                      -- Initialize the ContextMenu frame before use.
-- ContextMenu:Init() -- If using the local Mixin


Sample.Frame:SetSize(200, 200)
Sample.Frame:SetPoint("TOPLEFT", 100, -100)

Sample.Frame.TestButton = CreateFrame("Button", "SampleFrame_TestButton", Sample.Frame, "UIPanelButtonTemplate")
Sample.Frame.TestButton:SetText("Right Click Me")
Sample.Frame.TestButton:SetWidth(150)
Sample.Frame.TestButton:SetPoint("TOPLEFT", Sample.Frame.Inset, 10, -10)
Sample.Frame.TestButton:RegisterForClicks("AnyUp")
Sample.Frame.TestButton:SetScript("OnClick", function(self, button)
    if (button == "RightButton") then
        local tempTable = {}
        for i=1, 15 do
            table.insert(tempTable, {
                name = "Item " .. i
            })
        end


        local contextInfo = {
            title = "Sample Context Menu",
            parent = self,
            --maximumWidth = 300,
            menuItems = {
                {
                    header = {
                        name = "This is it",
                        menuItems = {
                            {
                                name = "First Sub Item",
                                icon = 134400,
                                tooltip = {
                                    title = "First!",
                                    lines = {
                                        {
                                            text = "First Line"
                                        },
                                        {
                                            text = "Second Line",
                                            type = "INSTRUCTION"
                                        },
                                        {
                                            text = "Third Line",
                                            type = "ERROR"
                                        }
                                    }
                                },
                                func = function()
                                    print("Clicked first!")
                                end
                            },
                            {
                                name = "Testing an absolute beast of a button name",
                                tooltip = {
                                    title = "SECOND with a check!",
                                    lines = {
                                        {
                                            text = "First Line"
                                        },
                                        {
                                            text = "Second Line",
                                            type = "INSTRUCTION"
                                        },
                                        {
                                            text = "Third Line",
                                            type = "ERROR"
                                        }
                                    }
                                },
                                isCheckbox = false,
                                isChecked = true,
                                func = function()
                                    print("Would check the box when it works")
                                end
                            }
                        }
                    }
                },
                {
                    name = "F",
                    icon = 134400,
                    isCheckbox = true,
                    tooltip = {
                        title = "First!",
                        lines = {
                            {
                                text = "First Line"
                            },
                            {
                                text = "Second Line",
                                type = "INSTRUCTION"
                            },
                            {
                                text = "Third Line",
                                type = "ERROR"
                            }
                        }
                    },
                    func = function()
                        print("Clicked first!")
                    end
                },
                {
                    name = "Second Item",
                    tooltip = {
                        title = "SECOND with a check!",
                        lines = {
                            {
                                text = "First Line"
                            },
                            {
                                text = "Second Line",
                                type = "INSTRUCTION"
                            },
                            {
                                text = "Third Line",
                                type = "ERROR"
                            }
                        }
                    },
                    isCheckbox = true,
                    isChecked = false,
                    func = function()
                        print("Would check the box when it works")
                    end
                },
                {
                    header = {
                        name = "Large stuff",
                        menuItems = tempTable
                    }
                }
            }
        }
        Sample.Frame:ShowContextMenu(contextInfo)
    end
end)




Sample.Frame:RegisterForDrag("LeftButton")
Sample.Frame:EnableMouse(true)
Sample.Frame:SetClampedToScreen(true)
Sample.Frame:SetMovable(true)

local isMoving = false
Sample.Frame:SetScript("OnDragStart", function(self, button)
    if (not isMoving) then
        self:StartMoving()
        isMoving = true
    end
end)
Sample.Frame:SetScript("OnDragStop", function(self, button)
    if (isMoving) then
        self:StopMovingOrSizing()
        isMoving = false
    end
end)
Sample.Frame:SetScript("OnHide", function(self)
    if (isMoving) then
        self:StopMovingOrSizing()
        isMoving = false
    end
end)


SLASH_SAMPLE1 = "/sample"
SlashCmdList["SAMPLE"] = function(msg)
    Sample.Frame:Show()
end
