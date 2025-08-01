-- Unified script with auto fishing logic, teleport, inventory, and enhancements

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

-- Window
local MainUI = Rayfield:CreateWindow({
    Name = "Fish It Script",
    LoadingTitle = "Fish It Script",
    LoadingSubtitle = "by Toi",
    Theme = "Amethyst",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "QuietXHub",
        FileName = "FishIt"
    },
    KeySystem = false
})

-- Tabs
local mainTab = MainUI:CreateTab("Main")
local playerTab = MainUI:CreateTab("Teleport")
local settingsTab = MainUI:CreateTab("Settings")

-- Net remotes (custom networking)
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SellRemote = Remotes.Server:FindFirstChild("SellAll") or Remotes:FindFirstChild("SellAllItems")
local EnchantRemote = Remotes.Server:FindFirstChild("ActivateEnchantingAltar") or Remotes:FindFirstChild("ActivateEnchant")

-- State
local autofish = false
local perfectCast = true
local autoRecastDelay = 1.4
local enchantPos = Vector3.new(3231, -1303, 1402)

-- Auto Fishing Toggle
mainTab:CreateToggle({
    Name = "Enable Auto Fish",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(value)
        autofish = value
        if value then
            task.spawn(function()
                while autofish do
                    pcall(function()
                        equipRemote:FireServer(1)
                        task.wait(0.1)

                        local timestamp = perfectCast and 9999999999 or (tick() + math.random())
                        rodRemote:InvokeServer(timestamp)
                        task.wait(0.1)

                        local x, y = -1.238, 0.969
                        if not perfectCast then
                            x = math.random(-1000, 1000) / 1000
                            y = math.random(0, 1000) / 1000
                        end
                        miniGameRemote:InvokeServer(x, y)
                        task.wait(1.3)

                        finishRemote:FireServer()
                    end)
                    task.wait(autoRecastDelay)
                end
            end)
        end
    end,
})

mainTab:CreateToggle({
    Name = "Use Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCast",
    Callback = function(val)
        perfectCast = val
    end,
})

mainTab:CreateSlider({
    Name = "Auto Recast Delay (seconds)",
    Range = {0.5, 5},
    Increment = 0.1,
    CurrentValue = autoRecastDelay,
    Callback = function(val)
        autoRecastDelay = val
    end
})

-- Auto Sell
mainTab:CreateButton({
    Name = "Sell All Fishes",
    Callback = function()
        if SellRemote then
            SellRemote:FireServer()
            Rayfield:Notify({ Title = "Auto Sell", Content = "All fish have been sold.", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Auto Sell", Content = "Sell remote not found!", Duration = 3 })
        end
    end
})

-- Enchant Rod
mainTab:CreateButton({
    Name = "Auto Enchant Rod",
    Callback = function()
        local char = Workspace.Characters:FindFirstChild(LocalPlayer.Name)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.CFrame = CFrame.new(enchantPos + Vector3.new(0, 5, 0))
        task.wait(1.2)

        if EnchantRemote then
            EnchantRemote:FireServer()
            Rayfield:Notify({ Title = "Enchant", Content = "Enchantment Activated!", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Enchant", Content = "Enchant remote not found!", Duration = 3 })
        end
    end
})

-- Inventory Print
mainTab:CreateButton({
    Name = "Print Inventory to Console",
    Callback = function()
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            print("-- INVENTORY CONTENTS --")
            for _, item in pairs(backpack:GetChildren()) do
                print(item.Name)
            end
        else
            print("Backpack not found!")
        end
    end
})

-- NPC List Teleport
local npcList = {}
for _, model in ipairs(Workspace:GetDescendants()) do
    if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
        table.insert(npcList, model.Name)
    end
end

playerTab:CreateDropdown({
    Name = "Teleport to NPC",
    Options = npcList,
    CurrentOption = nil,
    Callback = function(selected)
        for _, npc in ipairs(Workspace:GetDescendants()) do
            if npc:IsA("Model") and npc.Name == selected and npc:FindFirstChild("HumanoidRootPart") then
                local myChar = Workspace.Characters:FindFirstChild(LocalPlayer.Name)
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    myHRP.CFrame = npc.HumanoidRootPart.CFrame
                    Rayfield:Notify({ Title = "Teleport", Content = "Teleported to NPC: " .. selected, Duration = 3 })
                end
                break
            end
        end
    end
})

-- Manual Teleport Input
playerTab:CreateInput({
    Name = "Teleport to Player/NPC",
    PlaceholderText = "Enter name...",
    RemoveTextAfterFocusLost = true,
    Callback = function(targetName)
        local function teleportToTarget(hrp, label)
            local myChar = Workspace.Characters:FindFirstChild(LocalPlayer.Name)
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP and hrp then
                myHRP.CFrame = hrp.CFrame
                Rayfield:Notify({ Title = "Teleport", Content = "Teleported to " .. label, Duration = 3 })
            end
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player.Name:lower() == targetName:lower() or player.DisplayName:lower() == targetName:lower() then
                local targetChar = Workspace.Characters:FindFirstChild(player.Name)
                local hrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                teleportToTarget(hrp, player.DisplayName)
                return
            end
        end

        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") and descendant:FindFirstChild("HumanoidRootPart") then
                if descendant.Name:lower():find(targetName:lower()) then
                    teleportToTarget(descendant.HumanoidRootPart, descendant.Name)
                    return
                end
            end
        end

        Rayfield:Notify({ Title = "Teleport", Content = "Target not found: " .. targetName, Duration = 3 })
    end
})
