local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()



-- Create the main window

local Window = Rayfield:CreateWindow({

   Name = "Rope Swing Obby",

   LoadingTitle = "Loading UI...",

   LoadingSubtitle = "by Hodgey",

   ConfigurationSaving = {

      Enabled = true,

      FolderName = "RopeSwingConfig",

      FileName = "Config"

   }

})



-- Create the Automation tab

local AutomationTab = Window:CreateTab("Automation", 4483362458) -- 4483362458 is the automation icon ID



-- Add this at the top of your script
local AutoComplete = {
    Running = false
}

local AutoCrates = {
    Running = false
}

local AutoVIPCrates = {
    Running = false
}

local function TeleportToCheckpoint(number)
    print("=== Starting Teleport Function ===")
    local checkpoint = game:GetService("Workspace").Map.Checkpoints[tostring(number)]
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    print("Checkpoint number:", number)
    print("Checkpoint exists:", checkpoint ~= nil)
    
    if character and checkpoint then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            print("Teleporting to checkpoint", number)
            humanoidRootPart.CFrame = checkpoint.CFrame + Vector3.new(0, 5, 0)
            return true
        end
    end
    return false
end

-- Update the checkpoint check function
local function GetCurrentCheckpoint()
    local player = game.Players.LocalPlayer
    
    -- Get stage value directly
    if player and player:FindFirstChild("leaderstats") then
        local stage = player.leaderstats:FindFirstChild("Stage")
        if stage then
            -- Convert to number and validate
            local stageNum = tonumber(stage.Value)
            if stageNum and stageNum > 0 then
                print("Current stage:", stageNum)
                return stageNum
            else
                print("Invalid stage value:", stage.Value)
            end
        else
            print("Stage not found in leaderstats")
        end
    else
        print("Leaderstats not found")
    end
    
    -- If we can't get the stage value, start from 1
    print("Starting from stage 1")
    return 1
end

-- Update the VerifyCheckpoint function to handle checkpoint 100
local function VerifyCheckpoint(number)
    local player = game.Players.LocalPlayer
    if player and player:FindFirstChild("leaderstats") then
        local stage = player.leaderstats:FindFirstChild("Stage")
        if stage then
            -- Special case for checkpoint 100
            if number == 100 then
                return stage.Value == "1"  -- Check for stage 1 specifically
            else
                return tonumber(stage.Value) >= number
            end
        end
    end
    return false
end



-- Modify your AutoComplete toggle to use these functions

AutomationTab:CreateToggle({
    Name = "Auto Complete Stage",
    CurrentValue = false,
    Flag = "AutoComplete",
    Callback = function(Value)
        print("Toggle changed to:", Value)
        
        if Value then
            AutoComplete.Running = true
            
            task.spawn(function()
                -- Get current stage and immediately teleport to it
                local currentCheckpoint = GetCurrentCheckpoint()
                print("Starting/Resuming from stage:", currentCheckpoint)
                
                -- Initial teleport to current checkpoint
                local initialTeleport = TeleportToCheckpoint(currentCheckpoint)
                if not initialTeleport then
                    print("Failed to teleport to starting checkpoint, retrying...")
                    task.wait(0.35)
                    if not TeleportToCheckpoint(currentCheckpoint) then
                        print("Failed to teleport after retry, stopping auto complete")
                        AutoComplete.Running = false
                        return
                    end
                end
                
                -- Wait for initial teleport to register
                task.wait(0.5)
                
                while AutoComplete.Running and currentCheckpoint <= 100 do
                    local success = TeleportToCheckpoint(currentCheckpoint)
                    
                    if success then
                        print("Successfully teleported to checkpoint:", currentCheckpoint)
                        local attempts = 0
                        local maxAttempts = 10
                        
                        repeat
                            task.wait(0.35)
                            attempts = attempts + 1
                            
                            -- Check for verification
                            if VerifyCheckpoint(currentCheckpoint) then
                                print("Checkpoint", currentCheckpoint, "verified!")
                                
                                -- If we just verified checkpoint 100, teleport to door
                                if currentCheckpoint == 100 then
                                    print("Stage 100 completed, stopping teleport loop...")
                                    AutoComplete.Running = false
                                    task.wait(0.5)
                                    
                                    print("Teleporting to door...")
                                    local worldDoor = game:GetService("Workspace").Map.Other.NextWorldDoor
                                    local character = game.Players.LocalPlayer.Character
                                    if character and worldDoor then
                                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                                        if humanoidRootPart then
                                            humanoidRootPart.CFrame = worldDoor.CFrame + Vector3.new(0, 5, 0)
                                            print("Successfully teleported to door")
                                        end
                                    end
                                end
                                break
                            end
                            print("Waiting for checkpoint", currentCheckpoint, "to register... Attempt", attempts)
                        until attempts >= maxAttempts or not AutoComplete.Running
                        
                        if attempts >= maxAttempts then
                            print("Failed to verify checkpoint", currentCheckpoint, "retrying...")
                            continue
                        end
                        
                        currentCheckpoint = currentCheckpoint + 1
                    else
                        print("Failed to teleport, retrying...")
                        task.wait(0.35)
                    end
                end
            end)
        else
            AutoComplete.Running = false
            print("Auto Complete disabled")
        end
    end,
})



-- Update the Teleport to End button to use the same function

AutomationTab:CreateButton({
    Name = "Teleport to End",
    Callback = function()
        TeleportToCheckpoint(100)
    end,
})

-- Add after the "Teleport to End" button
AutomationTab:CreateButton({
    Name = "Teleport to Start",
    Callback = function()
        TeleportToCheckpoint(1)
    end,
})

-- Add after the "Teleport to Start" button
AutomationTab:CreateButton({
    Name = "Teleport to Door",
    Callback = function()
        local worldDoor = game:GetService("Workspace").Map.Other.NextWorldDoor
        local character = game.Players.LocalPlayer.Character
        
        if character and worldDoor then
            -- Try to find a valid part to teleport to
            local targetPart = worldDoor:FindFirstChild("NextWorldPart") 
                or worldDoor:FindFirstChild("TouchPart") 
                or worldDoor:FindFirstChild("Door") 
                or worldDoor.PrimaryPart 
                or worldDoor:FindFirstChildWhichIsA("BasePart")
            
            if targetPart then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
                    print("Successfully teleported to NextWorldDoor")
                end
            else
                print("Could not find a valid part to teleport to")
            end
        end
    end,
})

AutomationTab:CreateToggle({
    Name = "Auto Claim Crates",
    CurrentValue = false,
    Flag = "AutoCrates",
    Callback = function(Value)
        print("=== Auto Crate Toggle ===")
        print("Toggle state:", Value)
        
        if Value then
            AutoCrates.Running = true
            
            task.spawn(function()
                print("Task spawned successfully")
                
                while task.wait(0.5) do
                    if not AutoCrates.Running then 
                        print("Toggle turned off, breaking loop")
                        break 
                    end
                    
                    local crateGroupsFolder = game:GetService("ReplicatedStorage").Objects.CrateGroups
                    if crateGroupsFolder then
                        local rankGroups = {}
                        for _, rankGroup in pairs(crateGroupsFolder:GetChildren()) do
                            -- Skip VIP and Premium crates
                            if not (rankGroup.Name:match("VIP") or rankGroup.Name:match("Premium")) then
                                local rankNum = tonumber(rankGroup.Name:match("Rank (%d+)"))
                                if rankNum then
                                    table.insert(rankGroups, {
                                        num = rankNum,
                                        group = rankGroup
                                    })
                                end
                            else
                                print("Skipping VIP/Premium group:", rankGroup.Name)
                            end
                        end
                        
                        -- Sort rank groups by number
                        table.sort(rankGroups, function(a, b)
                            return a.num < b.num
                        end)
                        
                        -- Process groups in order
                        for _, rankData in ipairs(rankGroups) do
                            if not AutoCrates.Running then break end
                            
                            print("Processing rank group:", rankData.group.Name, "(Rank", rankData.num, ")")
                            
                            for _, crate in pairs(rankData.group:GetChildren()) do
                                if not AutoCrates.Running then break end
                                
                                local claimRemote = crate:FindFirstChild("Claim")
                                if claimRemote then
                                    claimRemote:FireServer()
                                    print("Claimed crate:", rankData.group.Name, crate.Name)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        else
            AutoCrates.Running = false
            print("Toggle turned off manually")
        end
    end,
})

-- Update the VIP crate toggle
AutomationTab:CreateToggle({
    Name = "Auto Claim VIP Crates",
    CurrentValue = false,
    Flag = "AutoVIPCrates",
    Callback = function(Value)
        print("=== Auto VIP Crate Toggle ===")
        print("Toggle state:", Value)
        
        if Value then
            AutoVIPCrates.Running = true
            
            task.spawn(function()
                print("VIP Task spawned successfully")
                
                while task.wait(0.5) do
                    if not AutoVIPCrates.Running then 
                        print("VIP Toggle turned off, breaking loop")
                        break 
                    end
                    
                    local crateGroupsFolder = game:GetService("ReplicatedStorage").Objects.CrateGroups
                    if crateGroupsFolder then
                        local rankGroups = {}
                        for _, rankGroup in pairs(crateGroupsFolder:GetChildren()) do
                            -- Only include VIP and Premium crates
                            if rankGroup.Name:match("VIP") or rankGroup.Name:match("Premium") then
                                local rankNum = tonumber(rankGroup.Name:match("Rank (%d+)"))
                                if rankNum then
                                    table.insert(rankGroups, {
                                        num = rankNum,
                                        group = rankGroup
                                    })
                                end
                            end
                        end
                        
                        -- Sort rank groups by number
                        table.sort(rankGroups, function(a, b)
                            return a.num < b.num
                        end)
                        
                        -- Process groups in order
                        for _, rankData in ipairs(rankGroups) do
                            if not AutoVIPCrates.Running then break end
                            
                            print("Processing VIP group:", rankData.group.Name, "(Rank", rankData.num, ")")
                            
                            for _, crate in pairs(rankData.group:GetChildren()) do
                                if not AutoVIPCrates.Running then break end
                                
                                local claimRemote = crate:FindFirstChild("Claim")
                                if claimRemote then
                                    claimRemote:FireServer()
                                    print("Claimed VIP crate:", rankData.group.Name, crate.Name)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        else
            AutoVIPCrates.Running = false
            print("VIP Toggle turned off manually")
        end
    end,
})



-- Keep the UI library loaded until the game closes

Rayfield:LoadConfiguration()



-- Add a Player tab for player modifications
local PlayerTab = Window:CreateTab("Player", 4483345998) -- Player icon

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
    end,
})

PlayerTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 250},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
      game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
   end,
})

