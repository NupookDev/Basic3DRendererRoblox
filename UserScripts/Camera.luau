local module = {}
local core = script.Parent.Parent.Core
local rendering = require(core.Rendering)
local library = require(core.Library)

local SEVENTY_DEG = math.rad(70)

local userInputService = game:GetService("UserInputService")

local angleX, angleY = 0, 0

function module.updateCamera(deltaTime: number)
	local mouseDelta = userInputService:GetMouseDelta()
	local deltaX, deltaY = mouseDelta.X, mouseDelta.Y
	local cameraDelta = deltaTime * 0.2

	angleY += deltaX * cameraDelta
	angleX = angleX - (deltaY * cameraDelta)

	if angleX > SEVENTY_DEG then
		angleX = SEVENTY_DEG
	elseif angleX < -SEVENTY_DEG then
		angleX = -SEVENTY_DEG
	end

	local sinY, cosY = math.sin(angleY), math.cos(angleY)
	local sinX, cosX = math.sin(angleX), math.cos(angleX)
	local camRotation: { { number } } = rendering.currentCamera.rotation

	camRotation[1][1], camRotation[1][2], camRotation[1][3] = cosY, -sinY * sinX, -sinY * cosX
	camRotation[2][1], camRotation[2][2], camRotation[2][3] = 0, cosX, -sinX
	camRotation[3][1], camRotation[3][2], camRotation[3][3] = sinY, cosY * sinX, cosY * cosX
end

function module.handleMovement(deltaTime: number)
	local moveDirection: { number } = { 0, 0, 0 }

	if userInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection[3] -= 1
	end

	if userInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection[3] += 1
	end

	if userInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDirection[1] -= 1
	end

	if userInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDirection[1] += 1
	end

	if userInputService:IsKeyDown(Enum.KeyCode.E) then
		moveDirection[2] += 1
	end

	if userInputService:IsKeyDown(Enum.KeyCode.Q) then
		moveDirection[2] -= 1
	end

	if library.normalize3D(moveDirection) then
		library.rotateVertex(moveDirection, rendering.currentCamera.rotation)

		if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			library.scaleVertex(moveDirection, deltaTime * 4)
		else
			library.scaleVertex(moveDirection, deltaTime * 8)
		end
		
		
		library.addVertex(rendering.currentCamera.position, moveDirection)
	end
end

return module
