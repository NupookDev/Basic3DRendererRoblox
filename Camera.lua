local module = {}
local rendering = require(script.Parent.Rendering)
local library = require(script.Parent.Library)

local SEVENTY_DEG = math.rad(70)

local userInputService = game:GetService("UserInputService")

local angleX, angleY = 0, 0

function module.updateCamera(camera: rendering.camera, deltaTime: number)
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

	camera.rotation[1][1], camera.rotation[1][2], camera.rotation[1][3] = cosY, -sinY * sinX, -sinY * cosX
	camera.rotation[2][1], camera.rotation[2][2], camera.rotation[2][3] = 0, cosX, -sinX
	camera.rotation[3][1], camera.rotation[3][2], camera.rotation[3][3] = sinY, cosY * sinX, cosY * cosX
end

function module.handleMovement(camera: rendering.camera, deltaTime: number)
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
		library.rotateVertex(moveDirection, camera.rotation)

		local moveDelta = deltaTime

		if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDelta *= 4
		else
			moveDelta *= 8
		end

		camera.position[1] += moveDirection[1] * moveDelta
		camera.position[2] += moveDirection[2] * moveDelta
		camera.position[3] += moveDirection[3] * moveDelta
	end
end

return module
