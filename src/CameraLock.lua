local camera = workspace.CurrentCamera
local gameField = workspace:WaitForChild("GameWall")
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70

game:GetService("RunService").RenderStepped:Connect(function()
	local center = gameField.Position
	local heightOffset = 4     
	local backOffset = 12   
	local heightOffset1 = 3
	local camPos = Vector3.new(center.X, center.Y + heightOffset1, center.Z + backOffset)
	local lookAt = Vector3.new(center.X, center.Y+ heightOffset, center.Z)
	camera.CFrame = CFrame.new(camPos, lookAt)
end)
