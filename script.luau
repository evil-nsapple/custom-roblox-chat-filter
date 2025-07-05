-- Put in ServerScriptService

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local bannedStore = DataStoreService:GetDataStore("ChatBannedUsers")

local bannedWordsUrl = "https://raw.githubusercontent.com/evil-nsapple/custom-roblox-chat-filter/refs/heads/main/list.txt"
local bannedWords = {}

local leetMap = {
    ["1"] = "i", ["!"] = "i", ["3"] = "e", ["4"] = "a", ["@"] = "a",
    ["5"] = "s", ["$"] = "s", ["7"] = "t", ["0"] = "o", ["9"] = "g"
}

local bannedUsers = {}

local function cleanMessage(msg)
    msg = msg:lower()
    for k, v in pairs(leetMap) do
        msg = msg:gsub(k, v)
    end
    msg = msg:gsub("[%p%s]", "")
    msg = msg:gsub("(%a)%1+", "%1")
    return msg
end

local function isFiltered(msg)
    local cleaned = cleanMessage(msg)
    for _, bad in ipairs(bannedWords) do
        if cleaned:find(bad:gsub("%s+", "")) then
            return true
        end
    end
    return false
end

local function loadBannedUsers()
    local success, data = pcall(function()
        return bannedStore:GetAsync("BannedUserIds")
    end)
    if success and type(data) == "table" then
        bannedUsers = data
        print("[BanSystem] Loaded banned users count:", #data)
    else
        bannedUsers = {}
        print("[BanSystem] No banned users loaded.")
    end
end

local function saveBannedUsers()
    pcall(function()
        bannedStore:SetAsync("BannedUserIds", bannedUsers)
    end)
end

local function banPlayer(player, reason)
    if not bannedUsers[player.UserId] then
        bannedUsers[player.UserId] = true
        saveBannedUsers()
    end
    warn("[FILTER BAN] "..player.Name.." banned for saying: "..reason)
    player:Kick("🔒 Permanently banned for: " .. reason)
end

local function fetchBannedWords()
    local success, response = pcall(function()
        return HttpService:GetAsync(bannedWordsUrl)
    end)
    if success and response then
        bannedWords = {}
        for line in response:gmatch("[^\r\n]+") do
            table.insert(bannedWords, line:lower())
        end
        print("[BanSystem] Loaded banned words count:", #bannedWords)
    else
        warn("[BanSystem] Failed to load banned words list from GitHub.")
    end
end

-- Init
fetchBannedWords()
loadBannedUsers()

Players.PlayerAdded:Connect(function(player)
    -- Kick immediately if banned
    if bannedUsers[player.UserId] then
        player:Kick("🔒 You are permanently banned.")
        return
    end

    player.Chatted:Connect(function(msg)
        if msg:lower() == "/banned" then
            local list = {}
            for userId,_ in pairs(bannedUsers) do
                table.insert(list, tostring(userId))
            end
            local message = "Banned UserIds: " .. (#list > 0 and table.concat(list, ", ") or "No banned users")
            player:SendNotification({Title = "Ban List", Text = message, Duration = 10})
            return
        end

        if isFiltered(msg) then
            banPlayer(player, msg)
        end
    end)
end)
