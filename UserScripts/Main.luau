--this is for playing

local module = {}
local core = script.Parent.Parent.Core
local objectsModule = require(core.Objects)
local rendering = require(core.Rendering)
local library = require(core.Library)
local objectsTest = require(script.Parent.ObjectTest)
local cameraModule = require(script.Parent.Camera)

local floppa = require(script.Parent.Parent.ImportedModels.Floppa)

local allUserCreatedBoxes: { objectsModule.object } = {}

local function testCreateBox(actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin or rendering.screenMode ~= rendering.ScreenMode.ENGINE then
		return
	end

	local worldPos: { number } = {}

	if rendering.screenToWorldPosition(worldPos, 120, 67) then
		local newObject: objectsModule.object
		local selectedNum = math.random(1, 3)

		if selectedNum == 1 then
			newObject = objectsModule.insertBox(worldPos[1], worldPos[2], worldPos[3], math.random(5, 20) * 0.1, math.random(5, 20) * 0.1, math.random(5, 20) * 0.1)
		elseif selectedNum == 2 then
			newObject = objectsModule.insertPyramid(worldPos[1], worldPos[2], worldPos[3], math.random(5, 20) * 0.1, math.random(5, 20) * 0.1, math.random(5, 20) * 0.1)
		else
			newObject = objectsModule.insertCone(worldPos[1], worldPos[2], worldPos[3], math.random(1, 2) * 0.5, math.random(1, 2) * 0.5)
		end

		local randColor: { number } = { math.random(0, 255), math.random(0, 255), math.random(0, 255) }
		library.copyVertex(newObject.color, randColor)
		allUserCreatedBoxes[#allUserCreatedBoxes + 1] = newObject
	end
end

local function testRemoveAllCreatedBox(actionName: string, inputState: Enum.UserInputState)
	for i = #allUserCreatedBoxes, 1, -1 do
		objectsModule.removeObject(allUserCreatedBoxes[i])
		allUserCreatedBoxes[i] = nil
	end
end

local function loop(deltaTime: number)
	if rendering.screenMode == rendering.ScreenMode.ENGINE then
		cameraModule.handleMovement(deltaTime)
		cameraModule.updateCamera(deltaTime)
	end

	local totalRadians = 0.5 * deltaTime
	local sinY, cosY = math.sin(totalRadians), math.cos(totalRadians)
	
	local rotation: { { number } } = {
		{ cosY, 0, sinY },
		{ 0, 1, 0 },
		{ -sinY, 0, cosY }
	}
	
	library.multiplyMatrix(floppa.rotation, rotation)
end

function module.init()
	objectsTest.initTestObjects()
	
	game:GetService("RunService").PreRender:Connect(loop)
	
	local contextActionService = game:GetService("ContextActionService")
	contextActionService:BindAction("createBox", testCreateBox, false, Enum.UserInputType.MouseButton1)
	contextActionService:BindAction("removeAllBoxes", testRemoveAllCreatedBox, false, Enum.KeyCode.R)
end

return module
