 
-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

-- Verify correct game ID
local targetGameId = 6701277882
if game.GameId ~= targetGameId then
    Rayfield:Notify({
        Title = "Invalid Game",
        Content = "This script only works in Fish It.",
        Duration = 6
    })
    return
end

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- Network references
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local RF_ChargeFishingRod = Net:WaitForChild("RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = Net:WaitForChild("RE/FishingCompleted")
local RE_EquipRod = Net:WaitForChild("RE/EquipToolFromHotbar")
local RE_ActivateEnchant = Net:WaitForChild("RE/ActivateEnchantingAltar")
local RF_SellAllItems = Net:WaitForChild("RF/SellAllItems")

-- Flags
local autoFishEnabled = false
local perfectCastEnabled = true

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- UI Setup
local MainUI = Rayfield:CreateWindow({
    Name = "AldyToi | 🎋 Fish It Script",
    LoadingTitle = "Fish It Script",
    LoadingSubtitle = "by AldyToi",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "AldyToi",
        FileName = "AutoFishSave"
    },
    KeySystem = false
})

-- Tabs
local devTab = MainUI:CreateTab("Developer", "airplay")
devTab:CreateParagraph({
    Title = "AldyToi Auto Fish It!",
    Content = "Thanks For Using This Script!\n\nDeveloper:\n-   Instagram: @aldytoi\n- GitHub: github.com/aldyjrz\n\nKeep supporting us!"
})
 

devTab:CreateButton({
    Name = "Instagram",
    Callback = function()
        setclipboard("https://instagram.com/aldytoi")
        Rayfield:Notify({
            Title = "Instagram",
            Content = "Link has been copied to clipboard!",
            Duration = 3
        })
    end
})

devTab:CreateButton({
    Name = "GitHub",
    Callback = function()
        setclipboard("https://github.com/aldyjrz")
        Rayfield:Notify({
            Title = "GitHub",
            Content = "Link has been copied to clipboard!",
            Duration = 3
        })
    end
})

-- Auto Fish Tab
local autoFishTab = MainUI:CreateTab("Auto Fish", "fish")
autoFishTab:CreateToggle({
    Name = "Enable Auto Fish",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(enabled)
        autoFishEnabled = enabled
        if not enabled then return end

        task.spawn(function()
            while autoFishEnabled do
                RE_EquipRod:FireServer(1)
                task.wait(0.2)
                local chargeDuration = perfectCastEnabled and 1.3 or 0.5
                RF_ChargeFishingRod:InvokeServer()
                task.wait(chargeDuration)
                RF_RequestFishingMinigameStarted:InvokeServer()
                task.wait(1.5)
                local hitZone = perfectCastEnabled and 0.968 or math.random()
                RE_FishingCompleted:FireServer(hitZone)
                task.wait(1.5)
            end
        end)
    end
})

autoFishTab:CreateToggle({
    Name = "Use Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCast",
    Callback = function(state)
        perfectCastEnabled = state
    end
})

autoFishTab:CreateButton({
    Name = "Manual Perfect Cast Now",
    Callback = function()
        RE_EquipRod:FireServer(1)
        task.wait(0.2)
        RF_ChargeFishingRod:InvokeServer()
        task.wait(1.3)
        RF_RequestFishingMinigameStarted:InvokeServer()
        task.wait(1.5)
        RE_FishingCompleted:FireServer(0.968)
    end
})

-- Feature Guide Tab
local guideTab = MainUI:CreateTab("Feature Guide", "book-text")
guideTab:CreateParagraph({
    Title = "All Features Guide",
    Content = "====| Auto Enchant Rod |====\n\nTo use Enchant Rod:\n1. Place Enchant Stone in Slot 5\n2. Make sure rod is equipped\n3. Press Auto Enchant\n\n====| Rod Modifier |====\nEach rod can only be changed once.\nMaximum boost is 1.5x.\nReset your character for changes to apply.\n\n====| Tab Event |====\nEvent Codes:\n1 = Ghost Shark Hunt\n2 = Shark Hunt\nEnter code in Event tab to teleport."
})

-- Auto Enchant Tab
local enchantPos = Vector3.new(3231, -1303, 1402)
autoFishTab:CreateButton({
    Name = "Auto Enchant Rod",
    Callback = function()
        local character = workspace:WaitForChild("Characters"):FindFirstChild(LocalPlayer.Name)
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then
            Rayfield:Notify({
                Title = "Auto Enchant Rod",
                Content = "Failed to find character HumanoidRootPart.",
                Duration = 3
            })
            return
        end
        Rayfield:Notify({
            Title = "🔧 Enchanting...",
            Content = "Please wait while the enchantment completes.",
            Duration = 7
        })
        task.wait(1)
        root.CFrame = CFrame.new(enchantPos + Vector3.new(0, 5, 0))
        task.wait(1.2)
        RE_EquipRod:FireServer(5) -- slot 5 is for Enchant Stone
        task.wait(0.5)
        RE_ActivateEnchant:FireServer()
        task.wait(7)
        Rayfield:Notify({
            Title = "Enchant",
            Content = "Successfully Enchanted!",
            Duration = 3
        })
    end
})

-- Sell Fish Button
autoFishTab:CreateButton({
    Name = "Sell All Fishes",
    Info = "Automatically sell all Fishes",
    Callback = function()
        local character = workspace:FindFirstChild("Characters")
        local playerChar = character and character:FindFirstChild(LocalPlayer.Name)
        local hrp = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Rayfield:Notify({
                Title = "Sell Fish",
                Content = "HumanoidRootPart not found.",
                Duration = 3
            })
            return
        end
        local sellPos = Vector3.new(-32, 5, 2885)
        hrp.CFrame = CFrame.new(sellPos)
        task.wait(1)
        pcall(function()
            RF_SellAllItems:InvokeServer()
        end)
        Rayfield:Notify({
            Title = "Sell Fish",
            Content = "All the fish were sold successfully.",
            Duration = 4
        })
    end
})

-- Teleport to Player Tab
local playerTab = MainUI:CreateTab("Player", "users-round")
playerTab:CreateInput({
    Name = "Teleport to Player",
    PlaceholderText = "Example: Prince",
    RemoveTextAfterFocusLost = false,
    Callback = function(name)
        local function teleportToPlayer(targetName)
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower() == targetName:lower() or p.DisplayName:lower() == targetName:lower() then
                    local char = workspace:FindFirstChild("Characters"):FindFirstChild(p.Name)
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local myChar = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            myHrp.CFrame = hrp.CFrame
                            Rayfield:Notify({
                                Title = "Teleport",
                                Content = "Successfully Teleported to " .. p.DisplayName,
                                Duration = 3
                            })
                        end
                    end
                    break
                end
            end
        end
        teleportToPlayer(name)
    end
})
