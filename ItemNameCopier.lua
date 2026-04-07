-- ==================================
-- ItemNameCopier v3.2 阻止搜索栏
-- ==================================

-- 数据库初始化
ItemNameCopierDB = ItemNameCopierDB or {}
ItemNameCopierDB.history = ItemNameCopierDB.history or {}
ItemNameCopierDB.favorites = ItemNameCopierDB.favorites or {}

local ENABLED = false -- 默认OFF
local MAX_HISTORY = 20

-- 前向声明：ShowFavoritesMenu 里的回调需要调用它
local ShowItem

-- ==================================
-- 根框体
-- ==================================
local frame = CreateFrame("Frame", "ItemNameCopierFrame", UIParent, "BackdropTemplate")
frame:SetSize(320, 32)
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- 延迟设置位置，确保存档数据已加载
local function RestoreFramePosition()
    frame:ClearAllPoints()
    frame:SetPoint(
        ItemNameCopierDB.point or "CENTER",
        UIParent,
        ItemNameCopierDB.relPoint or "CENTER",
        ItemNameCopierDB.x or 0,
        ItemNameCopierDB.y or 680
    )
end

-- 先设置默认位置，稍后更新为存档位置
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 680)

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    ItemNameCopierDB.point = p
    ItemNameCopierDB.relPoint = rp
    ItemNameCopierDB.x = x
    ItemNameCopierDB.y = y
end)
frame:Hide()

local function SetBackground(enabled)
    if enabled then
        frame:SetBackdropColor(0,0,0,0.9)
    else
        frame:SetBackdropColor(0.6,0,0,0.9)
    end
end

-- ==================================
-- Toggle 按钮
-- ==================================
local toggle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
toggle:SetSize(40, 20)
toggle:SetPoint("LEFT", 4, 0)
local function UpdateToggle()
    toggle:SetText(ENABLED and "ON" or "OFF")
    SetBackground(ENABLED)
end
toggle:SetScript("OnClick", function()
    ENABLED = not ENABLED
    UpdateToggle()
end)

-- ==================================
-- 关闭按钮
-- ==================================
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("RIGHT", -4, 0)
close:SetScript("OnClick", function() frame:Hide() end)

-- 判断下拉菜单是否已打开
local function IsDropDownMenuOpen()
    return _G.UIDROPDOWNMENU_OPEN_MENU ~= nil
end

-- ==================================
-- 收藏按钮
-- ==================================
local favBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
favBtn:SetSize(50,20)
favBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
favBtn:SetText("收藏")

-- 历史按钮
local historyBtn = CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
historyBtn:SetSize(50,20)
historyBtn:SetPoint("RIGHT",favBtn,"LEFT",-2,0)
historyBtn:SetText("历史")
historyBtn:SetHitRectInsets(0, 0, 0, 0)
historyBtn:SetFrameStrata("MEDIUM")
historyBtn:SetFrameLevel(frame:GetFrameLevel() + 10)

-- 新建收藏列表弹窗
StaticPopupDialogs["ITEMCOPIER_NEW_FAVLIST"] = {
    text = "输入新收藏列表名字",
    button1 = "保存",
    button2 = "取消",
    hasEditBox = true,
    maxLetters = 50,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        self.EditBox:SetFocus()
        self.EditBox:SetText("")
    end,
    OnAccept = function(self, data)
        local name = self.EditBox:GetText()
        local itemName = data
        if not name or name=="" then return end
        ItemNameCopierDB.favorites = ItemNameCopierDB.favorites or {}
        if not ItemNameCopierDB.favorites[name] then
            ItemNameCopierDB.favorites[name] = {}
        end
        local listTbl = ItemNameCopierDB.favorites[name]
        if itemName and itemName ~= "" and not tContains(listTbl,itemName) then
            table.insert(listTbl,itemName)
            print("|cff00ff00[ItemNameCopier]|r 收藏到新列表 "..name.." 成功")
        end
    end,
}

-- 重命名收藏列表弹窗
StaticPopupDialogs["ITEMCOPIER_RENAME_FAVLIST"] = {
    text = "重命名收藏列表",
    button1 = "确定",
    button2 = "取消",
    hasEditBox = true,
    maxLetters = 50,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        self.EditBox:SetFocus()
        self.EditBox:SetText(data or "")
    end,
    OnAccept = function(self, data)
        local oldName = data
        local newName = self.EditBox:GetText()
        if not newName or newName=="" or not oldName or oldName=="" or newName==oldName then return end
        if not ItemNameCopierDB.favorites[oldName] then return end
        if ItemNameCopierDB.favorites[newName] then
            print("|cffff0000[ItemNameCopier]|r 已存在同名列表")
            return
        end
        ItemNameCopierDB.favorites[newName] = ItemNameCopierDB.favorites[oldName]
        ItemNameCopierDB.favorites[oldName] = nil
        print("|cff00ff00[ItemNameCopier]|r 列表已重命名为 "..newName)
    end,
}

-- EditBox
local editBox = CreateFrame("EditBox", nil, frame)
editBox:SetPoint("LEFT", toggle, "RIGHT", 4, 0)
editBox:SetPoint("RIGHT", historyBtn, "LEFT", -2, 0)
editBox:SetHeight(20)
editBox:SetFontObject("ChatFontNormal")
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
editBox:SetScript("OnKeyDown", function(self,key)
    if IsControlKeyDown() and key=="C" then
        frame:SetBackdropColor(0,0.6,0,0.9)
        C_Timer.After(0.15,function() SetBackground(ENABLED) end)
        if AuctionFrame and AuctionFrame:IsShown() then
            if BrowseName and not BrowseName:IsVisible() then
                if AuctionFrameTab1 then AuctionFrameTab1:Click() end
            end
            if BrowseName then
                BrowseName:SetFocus()
                BrowseName:HighlightText()
            end
        end
    end
end)

-- ==================================
-- 收藏菜单（多级）
local function ShowFavoritesMenu()
    if not UIDropDownMenu_Initialize then
        UIParentLoadAddOn("Blizzard_UIDropDownMenu")
    end
    local menu = CreateFrame("Frame", "ItemNameCopierFavoritesMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menu,function(self,level,menuList)
        local favTbl = ItemNameCopierDB.favorites or {}
        if level == 1 then
            local keys = {}
            for listName in pairs(favTbl) do table.insert(keys, listName) end
            table.sort(keys)
            for _, listName in ipairs(keys) do
                local tbl = favTbl[listName]
                local info = UIDropDownMenu_CreateInfo()
                info.text = listName
                info.notCheckable = true
                info.hasArrow = true
                info.menuList = listName
                info.func = function()
                    StaticPopup_Show("ITEMCOPIER_RENAME_FAVLIST", nil, nil, listName)
                end
                UIDropDownMenu_AddButton(info, level)
            end
            -- 新建收藏列表按钮
            local info = UIDropDownMenu_CreateInfo()
            info.text = "新建收藏列表"
            info.notCheckable = true
            info.func = function()
                StaticPopup_Show("ITEMCOPIER_NEW_FAVLIST", nil, nil, nil)
            end
            UIDropDownMenu_AddButton(info, level)
            -- 删除菜单按钮
            local delInfo = UIDropDownMenu_CreateInfo()
            delInfo.text = "|cffff4040删除...|r"
            delInfo.notCheckable = true
            delInfo.hasArrow = true
            delInfo.menuList = "__DELETE__"
            UIDropDownMenu_AddButton(delInfo, level)
        elseif level == 2 and menuList then
            if menuList == "__DELETE__" then
                -- 删除菜单：显示所有列表
                local keys = {}
                for listName in pairs(favTbl) do table.insert(keys, listName) end
                table.sort(keys)
                for _, listName in ipairs(keys) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = listName
                    info.notCheckable = true
                    info.hasArrow = true
                    info.menuList = {__delete_list = listName}
                    info.func = function() -- 点击列表名删除该列表
                        ItemNameCopierDB.favorites[listName] = nil
                        CloseDropDownMenus()
                        C_Timer.After(0.1, ShowFavoritesMenu)
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            else
                -- 普通二级菜单：显示该列表物品
                local tbl = favTbl[menuList] or {}
                local items = {unpack(tbl)}
                table.sort(items)
                for idx, itemName in ipairs(items) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = itemName
                    info.notCheckable = true
                    info.func = function()
                        -- 点击收藏物品：填充并写入历史
                        -- itemName 在收藏中通常已带引号（ShowItem 会再加一次），这里去掉一层引号再交给 ShowItem
                        local raw = itemName
                        if type(raw) == "string" then
                            raw = raw:gsub('^"(.*)"$', "%1")
                        end
                        ShowItem(raw)
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        elseif level == 3 and type(menuList)=="table" and menuList.__delete_list then
            -- 删除菜单：显示该列表所有物品名
            local listName = menuList.__delete_list
            local tbl = favTbl[listName] or {}
            local items = {unpack(tbl)}
            table.sort(items)
            for idx, itemName in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = itemName
                info.notCheckable = true
                info.func = function()
                    for i,v in ipairs(tbl) do if v==itemName then table.remove(tbl, i) break end end
                    ItemNameCopierDB.favorites[listName] = tbl
                    CloseDropDownMenus()
                    C_Timer.After(0.1, ShowFavoritesMenu)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
    ToggleDropDownMenu(1,nil,menu,favBtn,0,0)
end

-- 历史菜单（多级）
local function ShowHistoryMenu()
    if not UIDropDownMenu_Initialize then
        UIParentLoadAddOn("Blizzard_UIDropDownMenu")
    end
    local menu = CreateFrame("Frame","ItemNameCopierHistoryMenu",UIParent,"UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menu,function(self,level,menuList)
        local historyTbl = ItemNameCopierDB.history or {}
        local favTbl = ItemNameCopierDB.favorites or {}
        if level == 1 then
            for i,name in ipairs(historyTbl) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.notCheckable = true
                info.hasArrow = true
                info.menuList = name
                info.arg1 = i
                info.func = function(self, idx)
                    -- 只保留左键填充，无右键删除
                    frame:Show()
                    editBox:SetText(name)
                    if ENABLED then
                        editBox:SetFocus()
                        editBox:HighlightText()
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            local clearInfo = UIDropDownMenu_CreateInfo()
            clearInfo.text = "|cffff4040清除全部记录|r"
            clearInfo.notCheckable = true
            clearInfo.func = function()
                ItemNameCopierDB.history = {}
                CloseDropDownMenus()
                C_Timer.After(0.1, ShowHistoryMenu)
            end
            UIDropDownMenu_AddButton(clearInfo, level)
        elseif level == 2 and menuList then
            for listName, tbl in pairs(favTbl) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = listName
                info.notCheckable = true
                info.func = function()
                    if not tContains(tbl, menuList) then
                        table.insert(tbl, menuList)
                        print("|cff00ff00[ItemNameCopier]|r 已加入到收藏列表 "..listName)
                    end
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end
            local info = UIDropDownMenu_CreateInfo()
            info.text = "新建收藏列表"
            info.notCheckable = true
            info.func = function()
                StaticPopup_Show("ITEMCOPIER_NEW_FAVLIST", nil, nil, menuList)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    ToggleDropDownMenu(1,nil,menu,historyBtn,0,0)
end

historyBtn:SetScript("OnClick",function()
    if IsDropDownMenuOpen() then
        CloseDropDownMenus()
    else
        ShowHistoryMenu()
    end
end)

favBtn:SetScript("OnClick",function()
    if IsDropDownMenuOpen() then
        CloseDropDownMenus()
    else
        ShowFavoritesMenu()
    end
end)

-- ==================================
-- 填充物品 & 历史
-- ==================================
ShowItem = function(name)
    frame:Show()
    name = '"'..name..'"'
    editBox:SetText(name)
    if ENABLED then
        editBox:SetFocus()
        editBox:HighlightText()
    end
    ItemNameCopierDB.history = ItemNameCopierDB.history or {}
    if not tContains(ItemNameCopierDB.history,name) then
        table.insert(ItemNameCopierDB.history,1,name)
        if #ItemNameCopierDB.history>MAX_HISTORY then
            table.remove(ItemNameCopierDB.history)
        end
    end
end

-- ==================================
-- Hook Shift/Control Click
-- ==================================
hooksecurefunc("HandleModifiedItemClick",function(link)
    if not link then return end
    if not (IsShiftKeyDown() or IsControlKeyDown()) then return end

    if ENABLED then
        if AuctionFrame and AuctionFrame:IsShown() and BrowseName and BrowseName:IsVisible() then
            BrowseName:ClearFocus()
        end
    end

    local name = link:match("%[(.-)%]")
    if name then ShowItem(name) end
end)

-- ==================================
-- 阻止 Shift/Ctrl 点击时把物品链接/名字写入拍卖行搜索框（BrowseName）
-- 说明：有些客户端路径不是调用 Insert（可能直接 SetText 或走 ChatEdit_InsertLink），
-- 因此同时对 SetText/Insert 做拦截，并在 BrowseName 获得焦点时吞掉 ChatEdit_InsertLink。
-- ==================================
local function HookAuctionSearchBoxInsert()
    if not BrowseName then return end
    if BrowseName.__ItemNameCopier_Hooked then return end

    BrowseName.__ItemNameCopier_Hooked = true

    -- 记录原方法
    if BrowseName.Insert and not BrowseName.__ItemNameCopier_OriginalInsert then
        BrowseName.__ItemNameCopier_OriginalInsert = BrowseName.Insert
        BrowseName.Insert = function(self, text)
            if ENABLED and AuctionFrame and AuctionFrame:IsShown() and (IsShiftKeyDown() or IsControlKeyDown()) then
                return
            end
            return self:__ItemNameCopier_OriginalInsert(text)
        end
    end

    if BrowseName.SetText and not BrowseName.__ItemNameCopier_OriginalSetText then
        BrowseName.__ItemNameCopier_OriginalSetText = BrowseName.SetText
        BrowseName.SetText = function(self, text)
            if ENABLED and AuctionFrame and AuctionFrame:IsShown() and (IsShiftKeyDown() or IsControlKeyDown()) then
                return
            end
            return self:__ItemNameCopier_OriginalSetText(text)
        end
    end
end

-- 若 Shift/Ctrl 点击导致走 ChatEdit_InsertLink，把目标是 BrowseName 的情况吞掉
hooksecurefunc("ChatEdit_InsertLink", function(link)
    if not link or type(link) ~= "string" then return end
    if not (IsShiftKeyDown() or IsControlKeyDown()) then return end

    if ENABLED and AuctionFrame and AuctionFrame:IsShown() and BrowseName and BrowseName:IsVisible() and BrowseName:HasFocus() then
        -- 直接清空，抵消可能的写入（不同客户端实现可能走 SetText）
        if BrowseName.ClearFocus then BrowseName:ClearFocus() end
        if BrowseName.SetText and BrowseName.__ItemNameCopier_OriginalSetText then
            BrowseName:__ItemNameCopier_OriginalSetText("")
        end
        return
    end
end)

-- ==================================
-- 聊天输入框打开时关闭插件
-- ==================================
local function HookChatEditBox()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and not editBox.__ItemNameCopier_Hooked then
            editBox.__ItemNameCopier_Hooked = true
            
            local origOnFocusGained = editBox:GetScript("OnEditFocusGained")
            editBox:SetScript("OnEditFocusGained", function(self)
                ENABLED = false
                UpdateToggle()
                if origOnFocusGained then origOnFocusGained(self) end
            end)
            
            local origOnFocusLost = editBox:GetScript("OnEditFocusLost")
            editBox:SetScript("OnEditFocusLost", function(self)
                if AuctionFrame and AuctionFrame:IsShown() then
                    ENABLED = true
                    UpdateToggle()
                end
                if origOnFocusLost then origOnFocusLost(self) end
            end)
        end
    end
end

-- ==================================
-- AH 打开默认 ON
-- ==================================
local evt = CreateFrame("Frame")
evt:RegisterEvent("AUCTION_HOUSE_SHOW")
evt:RegisterEvent("AUCTION_HOUSE_CLOSED")
evt:SetScript("OnEvent",function(self, e)
    if e == "AUCTION_HOUSE_SHOW" then
        ENABLED = true
        UpdateToggle()
        frame:Show()
        HookAuctionSearchBoxInsert()
    elseif e == "AUCTION_HOUSE_CLOSED" then
        ENABLED = false
        UpdateToggle()
    end
end)

-- ==================================
-- 监听插件插入链接（AtlasLoot / 第三方）
-- ==================================
hooksecurefunc("ChatEdit_InsertLink", function(link)
    if not ENABLED then return end
    if not link or type(link) ~= "string" then return end

    -- 只在 Shift / Ctrl 时生效，避免误触
    if not (IsShiftKeyDown() or IsControlKeyDown()) then return end

    local name = link:match("%[(.-)%]")
    if name then
        ShowItem(name)
    end
end)


-- 初始化
UpdateToggle()
HookChatEditBox()

-- 等待存档数据加载完毕，然后恢复位置
C_Timer.After(0.1, RestoreFramePosition)

-- 定期检查和hook新的聊天框
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    HookChatEditBox()
end)

print("|cff00ff00[ItemNameCopier] v3.2 - 拍卖行界面打开时自动开启|r")
