local rig = workspace.Capybara.CapybaraHero
local humanoid = rig:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local animationsFolder = rig:WaitForChild("Animations")

local anims = {
	LeftUp = animator:LoadAnimation(animationsFolder.LeftUp),
	LeftDown = animator:LoadAnimation(animationsFolder.LeftDown),
	RightUp = animator:LoadAnimation(animationsFolder.RightUp),
	RightDown = animator:LoadAnimation(animationsFolder.RightDown),
}

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, anim in pairs(anims) do anim:Stop() end 
	if input.KeyCode == Enum.KeyCode.E then
		anims.RightUp:Play()
	elseif input.KeyCode == Enum.KeyCode.A then
		anims.LeftDown:Play()
	elseif input.KeyCode == Enum.KeyCode.Q then
		anims.LeftUp:Play()
	elseif input.KeyCode == Enum.KeyCode.D then
		anims.RightDown:Play()
	end
end)
