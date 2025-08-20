-- CLIENT CONSOLE PASTE: Flight + Noclip (walls-only ground hover) + ESP + Infinite Jump + Minimize (RightCtrl) + Draggable
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")

    local player = Players.LocalPlayer
    if not player then return warn("Run this in the Client console (F9 → Client).") end

    -- ===== state =====
    local flying = false
    local noclipOn = false
    local espOn = false
    local infJumpOn = false
    local minimized = false
-- add near your other locals
local jumpConnBegin, jumpConnEnd
local canJumpAgain = true


    local bodyVel = nil
    local originals = {}
    local espHighlightByModel = {}
    local espConnAdded, espConnRemoving = nil, nil
    local jumpConn = nil

    -- character refs
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid  = character:WaitForChild("Humanoid")
    local root      = character:WaitForChild("HumanoidRootPart")

    local function rebindCharacter(c)
        character = c
        humanoid  = c:WaitForChild("Humanoid")
        root      = c:WaitForChild("HumanoidRootPart")
        if flying and root and not bodyVel then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVel.Velocity = Vector3.zero
            bodyVel.Parent = root
        end
        if noclipOn then
            originals = {}
            for _, d in ipairs(character:GetDescendants()) do
                if d:IsA("BasePart") then
                    originals[d] = d.CanCollide
                    d.CanCollide = false
                end
            end
        end
    end
    player.CharacterAdded:Connect(rebindCharacter)

    -- ===== GUI =====
    local GREEN = Color3.fromRGB(40,170,80)
    local RED   = Color3.fromRGB(170,40,50)
    local BTN   = Color3.fromRGB(70,70,70)
    local BG    = Color3.fromRGB(22,22,22)
    local BAR   = Color3.fromRGB(16,16,16)

    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("MovementGui")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MovementGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local window = Instance.new("Frame")
    window.Name = "Window"
window.Size = UDim2.new(0, 280, 0, 300) -- was 260; gives content ~260px tall
    window.Position = UDim2.new(0, 40, 0, 120)
    window.BackgroundColor3 = BG
    window.BorderSizePixel = 0
    window.Active = true
    window.Parent = gui

    -- Title bar (drag handle)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = BAR
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(220,220,220)
    title.Text = "made by tristanm5281"
    title.Parent = titleBar

    -- Contents
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -16, 1, -40)
    content.Position = UDim2.new(0, 8, 0, 36)
    content.BackgroundTransparency = 1
    content.Parent = window

    local function mkBtn(parent, text, y, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.Position = UDim2.new(0, 0, 0, y)
        b.Text = text
        b.BackgroundColor3 = color or BTN
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 14
        b.AutoButtonColor = true
        b.Parent = parent
        return b
    end

    local function mkBox(parent, ph, y, default)
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, 0, 0, 28)
        tb.Position = UDim2.new(0, 0, 0, y)
        tb.PlaceholderText = ph
        tb.Text = default or ""
        tb.BackgroundColor3 = Color3.fromRGB(50,50,50)
        tb.TextColor3 = Color3.new(1,1,1)
        tb.Font = Enum.Font.Gotham
        tb.TextSize = 14
        tb.ClearTextOnFocus = false
        tb.Parent = parent
        return tb
    end

    local speedBox  = mkBox(content, "Enter WalkSpeed", 0, "")
    local applyBtn  = mkBtn(content, "Apply Speed", 34, BTN)
    local flyBtn    = mkBtn(content, "Flight: OFF", 70, RED)
    local noclipBtn = mkBtn(content, "Noclip: OFF", 106, RED)
    local espBtn    = mkBtn(content, "ESP: OFF", 142, RED)
    local ijBtn     = mkBtn(content, "Infinite Jump: OFF", 178, RED)
    local unloadBtn = mkBtn(content, "Unload GUI", 214, Color3.fromRGB(150,50,50))

    local function setToggleVisual(button, on, onText, offText)
        button.Text = on and onText or offText
        button.BackgroundColor3 = on and GREEN or RED
    end

    -- ===== Dragging the window via title bar =====
    local dragging = false
    local dragOffset = Vector2.new()
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local mouse = UserInputService:GetMouseLocation()
            local pos = window.AbsolutePosition
            dragOffset = Vector2.new(mouse.X - pos.X, mouse.Y - pos.Y)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local m = UserInputService:GetMouseLocation()
            window.Position = UDim2.fromOffset(m.X - dragOffset.X, m.Y - dragOffset.Y)
        end
    end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        minimized = not minimized
        content.Visible = not minimized
        title.Text = minimized and "Player Tools (minimized)" or "Player Tools"
        -- hide/show the background by changing the window height
        window.Size = minimized and UDim2.new(0, 280, 0, 28) or UDim2.new(0, 280, 0, 300)
    end
end)


    -- ===== WalkSpeed =====
    applyBtn.MouseButton1Click:Connect(function()
        local v = tonumber(speedBox.Text)
        if v and humanoid then humanoid.WalkSpeed = v end
    end)

    -- ===== Flight =====
    local function enableFlight()
        if root and not bodyVel then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            bodyVel.Velocity = Vector3.zero
            bodyVel.Parent = root
        end
    end
    local function disableFlight()
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
    end

    flyBtn.MouseButton1Click:Connect(function()
        flying = not flying
        setToggleVisual(flyBtn, flying, "Flight: ON", "Flight: OFF")
        if flying then enableFlight() else disableFlight() end
    end)

    RunService.RenderStepped:Connect(function()
        if flying and bodyVel and root then
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            bodyVel.Velocity = move * 50
        end
    end)

    -- ===== Noclip (walls-only ground hover) =====
    local function enableNoclip()
        originals = {}
        for _, d in ipairs(character:GetDescendants()) do
            if d:IsA("BasePart") then
                originals[d] = d.CanCollide
                d.CanCollide = false
            end
        end
    end
    local function disableNoclip()
        for part, orig in pairs(originals) do
            if part and part:IsA("BasePart") then part.CanCollide = orig end
        end
        originals = {}
    end

    local function groundRay(origin)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { character }
        params.FilterType = Enum.RaycastFilterType.Blacklist
        return Workspace:Raycast(origin, Vector3.new(0,-200,0), params)
    end

    noclipBtn.MouseButton1Click:Connect(function()
        noclipOn = not noclipOn
        setToggleVisual(noclipBtn, noclipOn, "Noclip: ON", "Noclip: OFF")
        if noclipOn then enableNoclip() else disableNoclip() end
    end)

    RunService.Stepped:Connect(function()
        if noclipOn and character and root and humanoid then
            for p in pairs(originals) do
                if p and p:IsA("BasePart") then p.CanCollide = false end
            end
            if not flying then
                local hit = groundRay(root.Position + Vector3.new(0, 2, 0))
                if hit then
                    local groundY = hit.Position.Y
                    local pad = 1.5
                    local targetY = groundY + humanoid.HipHeight + pad
                    if root.Position.Y < targetY - 0.1 then
                        root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z, root.CFrame:components())
                    end
                end
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            else
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end
    end)

    -- ===== ESP =====
    local function isCharacterModel(m)
        if not m or not m:IsA("Model") then return false end
        if Players:GetPlayerFromCharacter(m) == player then return false end
        return m:FindFirstChildOfClass("Humanoid") ~= nil
    end

    local function addESP(m)
        if espHighlightByModel[m] then return end
        local h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillColor = Color3.fromRGB(0, 200, 255)
        h.FillTransparency = 0.75
        h.OutlineColor = Color3.fromRGB(0, 255, 170)
        h.OutlineTransparency = 0.0
        h.Adornee = m
        h.Parent = m
        espHighlightByModel[m] = h
    end

    local function removeESP(m)
        local h = espHighlightByModel[m]
        if h then h:Destroy() end
        espHighlightByModel[m] = nil
    end

    local function enableESP()
        -- existing
        for _, m in ipairs(Workspace:GetDescendants()) do
            if isCharacterModel(m) then addESP(m) end
        end
        -- new joins
        espConnAdded = Workspace.DescendantAdded:Connect(function(d)
            if isCharacterModel(d) then addESP(d) end
        end)
        espConnRemoving = Workspace.DescendantRemoving:Connect(function(d)
            if espHighlightByModel[d] then removeESP(d) end
        end)
    end

    local function disableESP()
        if espConnAdded then espConnAdded:Disconnect() espConnAdded = nil end
        if espConnRemoving then espConnRemoving:Disconnect() espConnRemoving = nil end
        for m,_ in pairs(espHighlightByModel) do removeESP(m) end
    end

    espBtn.MouseButton1Click:Connect(function()
        espOn = not espOn
        setToggleVisual(espBtn, espOn, "ESP: ON", "ESP: OFF")
        if espOn then enableESP() else disableESP() end
    end)

-- ===== Infinite Jump (requires release between jumps) =====
local function enableInfJump()
    -- clean up any previous listeners
    if jumpConnBegin then jumpConnBegin:Disconnect(); jumpConnBegin = nil end
    if jumpConnEnd   then jumpConnEnd:Disconnect();   jumpConnEnd   = nil end
    canJumpAgain = true

    jumpConnBegin = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not infJumpOn then return end
        if input.KeyCode == Enum.KeyCode.Space and not UserInputService:GetFocusedTextBox() then
            if canJumpAgain and humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                canJumpAgain = false   -- block until Space is released
            end
        end
    end)

    jumpConnEnd = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            canJumpAgain = true
        end
    end)
end

local function disableInfJump()
    if jumpConnBegin then jumpConnBegin:Disconnect(); jumpConnBegin = nil end
    if jumpConnEnd   then jumpConnEnd:Disconnect();   jumpConnEnd   = nil end
end

-- Button handler (make sure it sets canJumpAgain when turning on)
ijBtn.MouseButton1Click:Connect(function()
    infJumpOn = not infJumpOn
    setToggleVisual(ijBtn, infJumpOn, "Infinite Jump: ON", "Infinite Jump: OFF")
    if infJumpOn then
        canJumpAgain = true
        enableInfJump()
    else
        disableInfJump()
    end
end)

    -- ===== Unload =====
    unloadBtn.MouseButton1Click:Connect(function()
        flying = false
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
        if noclipOn then noclipOn = false; disableNoclip() end
        if espOn then espOn = false; disableESP() end
        if infJumpOn then infJumpOn = false; disableInfJump() end
        gui:Destroy()
    end)
end
