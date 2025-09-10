local game = game
local workspace = workspace
local Enum = Enum

local newVector = Vector3.new
local sin, cos, floor, round = math.sin, math.cos, math.floor, math.round
local fromRGB = Color3.fromRGB
local newInstance = Instance.new
local readu8 = buffer.readu8
local osClock = os.clock
local yield = task.wait
local formatStr = string.format

local repStore = game:GetService("ReplicatedStorage")

local library = require(repStore.Library)
local dot3D = library.dot3D
local cross = library.cross
local multiplyMatrix = library.multiplyMatrix
local rotateVertex = library.rotateVertex
local normalize3D = library.normalize3D
local computeBarry = library.computeBarry

local objectsModule = require(repStore.Objects)
local insertTestObjects = objectsModule.insertTestObjects

local WIDTH = 240
local HEIGHT = 135

local HUGE = math.huge
local HALF_PI = math.pi * 0.5
local ASPECT_RATIO_INV = 1 / (WIDTH / HEIGHT)

local pixels = {}
local zBuffer = {}

local function putPixel(x: number, y: number, color: { number })	
	pixels[x + 1][y + 1].Color = fromRGB(color[1], color[2], color[3])
end

local function getTexturePixel(result: { number }, texture: {}, u: number, v: number): { number }
	local xy = (round(u * (texture.size[1] - 1)) + (round(v * (texture.size[2] - 1)) * texture.size[1])) * 3
	
	result[1] = readu8(texture.data, xy)
	result[2] = readu8(texture.data, xy + 1)
	result[3] = readu8(texture.data, xy + 2)
end

local lightDirection = { -sin(0.79), cos(0.79), 0 }

local function drawTriangle(projected: { { number } }, UVCoords: { { number } }, worldSpace: { { number } }, texture: {}, color: { number })	
	local xMin, yMin = projected[1][1], projected[1][2]
	local xMax, yMax = xMin, yMin
	local currentVertex
	
	for i = 2, 3, 1 do
		currentVertex = projected[i]

		if currentVertex[1] < xMin then
			xMin = currentVertex[1]
		elseif currentVertex[1] > xMax then
			xMax = currentVertex[1]
		end

		if currentVertex[2] < yMin then
			yMin = currentVertex[2]
		elseif currentVertex[2] > yMax then
			yMax = currentVertex[2]
		end
	end
	
	if xMin < 0 then
		xMin = 0
	elseif xMin >= WIDTH then
		xMin = WIDTH - 1
	end
	
	if xMax < 0 then
		xMax = 0
	elseif xMax >= WIDTH then
		xMax = WIDTH - 1
	end
	
	if yMin < 0 then
		yMin = 0
	elseif yMin >= HEIGHT then
		yMin = HEIGHT - 1
	end
	
	if yMax < 0 then
		yMax = 0
	elseif yMax >= HEIGHT then
		yMax = HEIGHT - 1
	end
	
	local vertex0, vertex1, vertex2 = worldSpace[1], worldSpace[2], worldSpace[3]
	local crossProduct = {}
	
	cross(crossProduct, { vertex1[1] - vertex0[1], vertex1[2] - vertex0[2], vertex1[3] - vertex0[3] }, { vertex2[1] - vertex0[1], vertex2[2] - vertex0[2], vertex2[3] - vertex0[3] })
	
	local lightDot
	
	if normalize3D(crossProduct) == 1 then
		lightDot = dot3D(crossProduct, lightDirection)

		if lightDot < 0 then
			lightDot = -lightDot
		end
		
		lightDot = (lightDot + 1) * 0.5
	else
		lightDot = 0
	end
	
	vertex0, vertex1, vertex2 = projected[1], projected[2], projected[3]
	
	local barryMatrix = { {}, {} }
	
	barryMatrix[1][1], barryMatrix[1][2] = vertex0[1] - vertex2[1], vertex1[1] - vertex2[1]
	barryMatrix[2][1], barryMatrix[2][2] = vertex0[2] - vertex2[2], vertex1[2] - vertex2[2]
	
	local barryResult = {}
	local z
	local luaX, luaY
	local texturePixel = {}
	
	if texture then
		local ut, vt
		local perspectiveCorrectW
		local perspectiveU, perspectiveV, perspectiveW
		
		for y = yMin, yMax, 1 do
			for x = xMin, xMax, 1 do
				barryMatrix[1][3], barryMatrix[2][3] = x - vertex2[1], y - vertex2[2]
				
				if computeBarry(barryResult, barryMatrix) == 0 then
					continue
				end
				
				perspectiveCorrectW = 1 / ((barryResult[1] * vertex0[3]) + (barryResult[2] * vertex1[3]) + (barryResult[3] * vertex2[3]))
				z = (barryResult[1] + barryResult[2] + barryResult[3]) * perspectiveCorrectW
				
				luaX, luaY = x + 1, y + 1
				
				if z >= zBuffer[luaX][luaY] then
					continue
				end
				
				zBuffer[luaX][luaY] = z
				
				perspectiveU = barryResult[1] * vertex0[3]
				perspectiveV = barryResult[2] * vertex1[3]
				perspectiveW = barryResult[3] * vertex2[3]

				ut = ((perspectiveU * UVCoords[1][1]) + (perspectiveV * UVCoords[2][1]) + (perspectiveW * UVCoords[3][1])) * perspectiveCorrectW
				vt = ((perspectiveU * UVCoords[1][2]) + (perspectiveV * UVCoords[2][2]) + (perspectiveW * UVCoords[3][2])) * perspectiveCorrectW
				
				getTexturePixel(texturePixel, texture, ut, vt)
				
				texturePixel[1] *= lightDot
				texturePixel[2] *= lightDot
				texturePixel[3] *= lightDot
				
				putPixel(x, y, texturePixel)
			end
		end
		
		return
	end
	
	for y = yMin, yMax, 1 do
		for x = xMin, xMax, 1 do
			barryMatrix[1][3], barryMatrix[2][3] = x - vertex2[1], y - vertex2[2]

			if computeBarry(barryResult, barryMatrix) == 0 then
				continue
			end

			z = (barryResult[1] + barryResult[2] + barryResult[3]) / ((barryResult[1] * vertex0[3]) + (barryResult[2] * vertex1[3]) + (barryResult[3] * vertex2[3]))

			luaX, luaY = x + 1, y + 1

			if z >= zBuffer[luaX][luaY] then
				continue
			end

			zBuffer[luaX][luaY] = z
			
			texturePixel[1] = color[1] * lightDot
			texturePixel[2] = color[2] * lightDot
			texturePixel[3] = color[3] * lightDot
			
			putPixel(x, y, texturePixel)
		end
	end
end

local function renderObjects(objects: {}, camera: {}) --im bout to crash out, I didnt get into triam udom
	local transposedRotation = { {}, {}, {} }
	
	for i = 1, 3, 1 do --transpose camera rotation matrix
		for j = 1, 3, 1 do
			transposedRotation[i][j] = camera.rotation[j][i]
		end
	end
	
	local object	
	local face
	local projected = {}
	local worldSpace = {}
	local vertex = {}
	local wInv
	local projectedPoints = {}
	local uvPoints = {}
	local worldSpacePoints = {}
	
	for i = 1, #objects, 1 do
		object = objects[i]
		
		for i = 1, #object.verticies, 1 do
			vertex[1] = object.verticies[i][1]
			vertex[2] = object.verticies[i][2]
			vertex[3] = object.verticies[i][3]
			
			rotateVertex(vertex, object.rotation)
			vertex[1] += object.position[1]
			vertex[2] += object.position[2]
			vertex[3] += object.position[3]
			
			worldSpace[i] = { vertex[1], vertex[2], vertex[3] }
			
			vertex[1] -= camera.position[1]
			vertex[2] -= camera.position[2]
			vertex[3] -= camera.position[3]
			rotateVertex(vertex, transposedRotation)
			
			if vertex[3] >= -2 then
				projected[i] = 0
				continue
			end
			
			wInv = 1 / -vertex[3]
			
			projected[i] = {
				floor(((vertex[1] * ASPECT_RATIO_INV * wInv) + 1) * 0.5 * (WIDTH - 1)),
				floor((1 - (vertex[2] * wInv)) * 0.5 * (HEIGHT - 1)),
				wInv
			}
		end
		
		for i = 1, #object.faces, 1 do
			face = object.faces[i]
			
			if projected[face[1]] == 0 or projected[face[2]] == 0 or projected[face[3]] == 0 then
				continue
			end
			
			projectedPoints[1] = projected[face[1]]
			projectedPoints[2] = projected[face[2]]
			projectedPoints[3] = projected[face[3]]
			
			uvPoints[1] = object.uv[face[4]]
			uvPoints[2] = object.uv[face[5]]
			uvPoints[3] = object.uv[face[6]]
			
			worldSpacePoints[1] = worldSpace[face[1]]
			worldSpacePoints[2] = worldSpace[face[2]]
			worldSpacePoints[3] = worldSpace[face[3]]
			
			drawTriangle(
				projectedPoints,
				uvPoints,
				worldSpacePoints,
				object.texture,
				object.color
			)
		end
	end
end

--MAIN

local userInputService = game:GetService("UserInputService")
local screenMode = 0
local workspaceCamera = workspace.Camera
local screenCamZOffset = newVector(0, 0, 75)
local zKeyDown = false

local function checkScreen()	
	if userInputService:IsKeyDown(Enum.KeyCode.Z) then
		if not zKeyDown then
			zKeyDown = true

			if screenMode == 0 then
				workspaceCamera.CameraType = Enum.CameraType.Scriptable
				workspaceCamera.CFrame = pixels[1][1].CFrame:Lerp(pixels[WIDTH][HEIGHT].CFrame, 0.5) + screenCamZOffset
				userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				userInputService.MouseIconEnabled = false
				screenMode = 1
			else
				workspaceCamera.CameraType = Enum.CameraType.Custom
				userInputService.MouseBehavior = Enum.MouseBehavior.Default
				userInputService.MouseIconEnabled = true
				screenMode = 0
			end
		end
	else
		zKeyDown = false
	end
end

local objects = objectsModule.objects

local camera = {
	position = { 0, 1.5, 4 },
	rotation = {
		{ 1, 0, 0 },
		{ 0, 1, 0 },
		{ 0, 0, 1 }
	}
}

local blackColor = fromRGB(0, 0, 0)
local angleX, angleY = 0, 0
local deltaTime

local function mainLoop()
	for x = 1, WIDTH, 1 do --clear screen
		for y = 1, HEIGHT, 1 do
			pixels[x][y].Color = blackColor
			zBuffer[x][y] = HUGE
		end
	end
	
	if screenMode == 1 then
		local mouseDelta = userInputService:GetMouseDelta()
		local deltaX, deltaY = mouseDelta.X, mouseDelta.Y
		local cameraDelta = deltaTime * 0.2
		
		angleY += deltaX * cameraDelta
		angleX = angleX - (deltaY * cameraDelta)
		
		if angleX > HALF_PI then
			angleX = HALF_PI
		elseif angleX < -HALF_PI then
			angleX = -HALF_PI
		end
		
		local sinY, cosY = sin(angleY), cos(angleY)
		local sinX, cosX = sin(angleX), cos(angleX)
		
		camera.rotation[1][1], camera.rotation[1][2], camera.rotation[1][3] = cosY, -sinY * sinX, -sinY * cosX
		camera.rotation[2][1], camera.rotation[2][2], camera.rotation[2][3] = 0, cosX, -sinX
		camera.rotation[3][1], camera.rotation[3][2], camera.rotation[3][3] = sinY, cosY * sinX, cosY * cosX
		
		local moveDirection = { 0, 0, 0 }
		
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
		
		if normalize3D(moveDirection) == 1 then
			rotateVertex(moveDirection, camera.rotation)

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
	
	--TEST--
	do
		local totalRotation = 0.78 * deltaTime
		local sinY, cosY = sin(totalRotation), cos(totalRotation)
		
		multiplyMatrix(objects[1].rotation, {
			{ cosY, 0, -sinY },
			{ 0, 1, 0 },
			{ sinY, 0, cosY }
		})
		
		local pyramidMove = { 0, 0, 0 }
		
		if userInputService:IsKeyDown(Enum.KeyCode.U) then
			pyramidMove[3] -= 1
		end
		
		if userInputService:IsKeyDown(Enum.KeyCode.H) then
			pyramidMove[1] -= 1
		end
		
		if userInputService:IsKeyDown(Enum.KeyCode.J) then
			pyramidMove[3] += 1
		end
		
		if userInputService:IsKeyDown(Enum.KeyCode.K) then
			pyramidMove[1] += 1
		end
		
		if userInputService:IsKeyDown(Enum.KeyCode.I) then
			pyramidMove[2] += 1
		end
		
		if userInputService:IsKeyDown(Enum.KeyCode.Y) then
			pyramidMove[2] -= 1
		end
		
		if normalize3D(pyramidMove) == 1 then
			rotateVertex(pyramidMove, camera.rotation)
			
			local moveDelta = deltaTime * 3
			
			objects[1].position[1] += pyramidMove[1] * moveDelta
			objects[1].position[2] += pyramidMove[2] * moveDelta
			objects[1].position[3] += pyramidMove[3] * moveDelta
		end
	end
	--END--
		
	renderObjects(objects, camera)
end

local pixelFolder = newInstance("Folder")

pixelFolder.Name = "PixelFolder"
pixelFolder.Parent = workspace

local partSize = newVector(0.5, 0.5, 0.5)
local part

for x = 1, WIDTH, 1 do
	pixels[x] = {}
	zBuffer[x] = {}

	for y = 1, HEIGHT, 1 do
		part = newInstance("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.Size = partSize
		part.Position = newVector(x * 0.5, (HEIGHT - y) * 0.5, 0)
		part.Parent = pixelFolder
		part.Name = formatStr("%d:%d", x, y)
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		pixels[x][y] = part
		zBuffer[x][y] = HUGE
	end
end

insertTestObjects()

local player = game:GetService("Players").LocalPlayer

while player.Character == nil do
	yield()
end

local lastTime = osClock()

while true do
	yield()
	deltaTime = osClock() - lastTime
	lastTime = osClock()
	checkScreen()
	mainLoop()
end
