local rendering = require(script.Rendering)
local objectsModule = require(script.Objects)
local objectTest = require(script.ObjectTest)
local cameraModule = require(script.Camera)
local library = require(script.Library)
local floppa = require(script.ImportedModels.Floppa)

local camera: rendering.camera = {
	position = { 0, 1.5, 4 },
	rotation = {
		{ 1, 0, 0 },
		{ 0, 1, 0 },
		{ 0, 0, 1 }
	}
}

local function loop(deltaTime: number)
	if rendering.screenMode == 1 then
		cameraModule.handleMovement(camera, deltaTime)
		cameraModule.updateCamera(camera, deltaTime)
	end
	
	local totalRadians = 0.5 * deltaTime
	local sinY, cosY = math.sin(totalRadians), math.cos(totalRadians)
	
	library.multiplyMatrix(floppa.rotation, {
		{ cosY, 0, sinY },
		{ 0, 1, 0 },
		{ -sinY, 0, cosY }
	})
end

local function testCreateBox(actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin or rendering.screenMode ~= rendering.ScreenMode.ENGINE then
		return
	end
	
	local worldPos: { number } = {}
	
	if rendering.screenToWorldPosition(worldPos, camera, 120, 67) then
		local newObject: objectsModule.object
		local selectedNum = math.random(1, 3)
		
		if selectedNum == 1 then
			newObject = objectsModule.insertBox(worldPos, { math.random(5, 20) * 0.1, math.random(5, 20) * 0.1, math.random(5, 20) * 0.1 })
		elseif selectedNum == 2 then
			newObject = objectsModule.insertPyramid(worldPos, { math.random(5, 20) * 0.1, math.random(5, 20) * 0.1, math.random(5, 20) * 0.1 })
		else
			newObject = objectsModule.insertCone(worldPos, math.random(1, 2) * 0.5, math.random(1, 2) * 0.5)
		end
		
		local randColor: { number } = { math.random(0, 255), math.random(0, 255), math.random(0, 255) }
		library.copyVertex(newObject.color, randColor)
	end
end

local function main()
	rendering.initScreen()
	objectTest.initTestObjects()
	game:GetService("ContextActionService"):BindAction("createBox", testCreateBox, false, Enum.UserInputType.MouseButton1)
	
	local runService = game:GetService("RunService")
	local lastTime = os.clock()

	while true do
		runService.PreRender:Wait()
		
		local currentTime = os.clock()
		local deltaTime = currentTime - lastTime
		lastTime = currentTime
		
		loop(deltaTime)
		rendering.routine(objectsModule.objects, objectsModule.objectCount, camera)
	end
end

main()
