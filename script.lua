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
