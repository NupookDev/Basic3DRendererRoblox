local newVector = Vector3.new
local sin, cos, floor, round = math.sin, math.cos, math.floor, math.round
local fromRGB = Color3.fromRGB
local newInstance = Instance.new
local readu8 = buffer.readu8
local osClock = os.clock
local formatStr = string.format

local repStore = game:GetService("ReplicatedStorage")

local library = require(repStore.Library)
local dot3D = library.dot3D
local cross = library.cross
local rotateVertex = library.rotateVertex
local normalize3D = library.normalize3D
local computeBarry = library.computeBarry

local objectsModule = require(repStore.Objects)
local insertTestObjects = objectsModule.insertTestObjects

local test = require(repStore.Test)
local testSpinThings = test.spinThings

local WIDTH = 240
local HEIGHT = 135

local HUGE = math.huge
local HALF_PI = math.pi * 0.5
local ASPECT_RATIO_INV = 1 / (WIDTH / HEIGHT)

local NEAR_PLANE_Z = -1
local INV_NEAR_PLANE_Z = 1 / -NEAR_PLANE_Z

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
	
	for i = 2, 3, 1 do
		local currentVertex = projected[i]

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
	local texturePixel = {}
	
	if texture then
		for y = yMin, yMax, 1 do
			for x = xMin, xMax, 1 do
				barryMatrix[1][3], barryMatrix[2][3] = x - vertex2[1], y - vertex2[2]
				
				if computeBarry(barryResult, barryMatrix) == 0 then
					continue
				end
				
				local perspectiveCorrectW = 1 / ((barryResult[1] * vertex0[3]) + (barryResult[2] * vertex1[3]) + (barryResult[3] * vertex2[3]))
				local z = -perspectiveCorrectW
				local luaX, luaY = x + 1, y + 1
				
				if z <= zBuffer[luaX][luaY] then
					continue
				end
				
				zBuffer[luaX][luaY] = z
				
				local perspectiveU = barryResult[1] * vertex0[3]
				local perspectiveV = barryResult[2] * vertex1[3]
				local perspectiveW = barryResult[3] * vertex2[3]
				local ut = ((perspectiveU * UVCoords[1][1]) + (perspectiveV * UVCoords[2][1]) + (perspectiveW * UVCoords[3][1])) * perspectiveCorrectW
				local vt = ((perspectiveU * UVCoords[1][2]) + (perspectiveV * UVCoords[2][2]) + (perspectiveW * UVCoords[3][2])) * perspectiveCorrectW
				
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

			local z = 1 / -((barryResult[1] * vertex0[3]) + (barryResult[2] * vertex1[3]) + (barryResult[3] * vertex2[3]))
			local luaX, luaY = x + 1, y + 1

			if z <= zBuffer[luaX][luaY] then
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

local function copyVertex(vertex0: { number }, vertex1: { number })
	vertex0[1] = vertex1[1]
	vertex0[2] = vertex1[2]
	vertex0[3] = vertex1[3]
end

local function clipToScreenX(x: number, wInv: number)
	return floor(((x * ASPECT_RATIO_INV * wInv) + 1) * 0.5 * (WIDTH - 1))
end

local function clipToScreenY(y: number, wInv: number)
	return floor((1 - (y * wInv)) * 0.5 * (HEIGHT - 1))
end

local function getNearClippedVertex(result: { number }, resultUV: { number }, vertex0: { number }, vertex1: { number }, uv0: { number }, uv1: { number })
	local zDist = vertex1[3] - vertex0[3]
	local t = (NEAR_PLANE_Z - vertex0[3]) / zDist
	
	result[1] = clipToScreenX(vertex0[1] + ((vertex1[1] - vertex0[1]) * t), INV_NEAR_PLANE_Z)
	result[2] = clipToScreenY(vertex0[2] + ((vertex1[2] - vertex0[2]) * t), INV_NEAR_PLANE_Z)
	result[3] = INV_NEAR_PLANE_Z
	
	resultUV[1] = uv0[1] + ((uv1[1] - uv0[1]) * t)
	resultUV[2] = uv0[2] + ((uv1[2] - uv0[2]) * t)
end

local function renderObjects(objects: {}, camera: {})
	local transposedRotation = { {}, {}, {} }
	
	for i = 1, 3, 1 do --transpose camera rotation matrix
		for j = 1, 3, 1 do
			transposedRotation[i][j] = camera.rotation[j][i]
		end
	end
	
	local vertex = {}
	
	local projected = {}
	local worldSpace = {}
	local clipspace = {}
	local inPlane = {}
	
	local projectedPoints = { {}, {}, {} }
	local uvPoints = { {}, {}, {} }
	local worldSpacePoints = { {}, {}, {} }
	
	local outBounds = { {}, {}, {} }
	local inBounds = { {}, {}, {} }
	
	for i = 1, objectsModule.objectCount, 1 do
		local object = objects[i]
		
		for i = 1, object.vertexCount, 1 do
			vertex[1] = object.verticies[i][1]
			vertex[2] = object.verticies[i][2]
			vertex[3] = object.verticies[i][3]
			
			rotateVertex(vertex, object.rotation)
			vertex[1] += object.position[1]
			vertex[2] += object.position[2]
			vertex[3] += object.position[3]
			
			if worldSpace[i] == nil then
				worldSpace[i] = {}
			end
			
			copyVertex(worldSpace[i], vertex)
			
			vertex[1] -= camera.position[1]
			vertex[2] -= camera.position[2]
			vertex[3] -= camera.position[3]
			rotateVertex(vertex, transposedRotation)
			
			if clipspace[i] == nil then
				clipspace[i] = {}
			end
			
			copyVertex(clipspace[i], vertex)
			
			if projected[i] == nil then
				projected[i] = {}
			end
			
			if vertex[3] > NEAR_PLANE_Z then
				inPlane[i] = 0
				continue
			end
			
			inPlane[i] = 1
			
			local wInv = 1 / -vertex[3]
			
			projected[i][1] = clipToScreenX(vertex[1], wInv)
			projected[i][2] = clipToScreenY(vertex[2], wInv)
			projected[i][3] = wInv
		end
		
		for i = 1, object.faceCount, 1 do
			local face = object.faces[i]
			local uv = object.uv
			local outBoundsCount, inBoundsCount = 0, 0
			
			for i = 1, 3, 1 do
				if inPlane[face[i]] == 0 then
					outBoundsCount += 1
					outBounds[outBoundsCount].clip = clipspace[face[i]]
					outBounds[outBoundsCount].uv = uv[face[i + 3]]
				else
					inBoundsCount += 1
					inBounds[inBoundsCount].clip = clipspace[face[i]]
					inBounds[inBoundsCount].uv = uv[face[i + 3]]
					inBounds[inBoundsCount].projected = projected[face[i]]
				end
			end
			
			if outBoundsCount == 3 then
				continue
			end
			
			for i = 1, 3, 1 do
				copyVertex(worldSpacePoints[i], worldSpace[face[i]])
			end
			
			if outBoundsCount == 2 then
				copyVertex(projectedPoints[1], inBounds[1].projected)
				copyVertex(uvPoints[1], inBounds[1].uv)
				
				getNearClippedVertex(projectedPoints[2], uvPoints[2], inBounds[1].clip, outBounds[1].clip, inBounds[1].uv, outBounds[1].uv)
				getNearClippedVertex(projectedPoints[3], uvPoints[3], inBounds[1].clip, outBounds[2].clip, inBounds[1].uv, outBounds[2].uv)
			elseif outBoundsCount == 1 then
				for i = 1, 2, 1 do
					copyVertex(projectedPoints[i], inBounds[i].projected)
					copyVertex(uvPoints[i], inBounds[i].uv)
				end
				
				getNearClippedVertex(projectedPoints[3], uvPoints[3], inBounds[1].clip, outBounds[1].clip, inBounds[1].uv, outBounds[1].uv)

				drawTriangle(
					projectedPoints,
					uvPoints,
					worldSpacePoints,
					object.texture,
					object.color
				)
				
				getNearClippedVertex(projectedPoints[1], uvPoints[1], inBounds[2].clip, outBounds[1].clip, inBounds[2].uv, outBounds[1].uv)
			else
				for i = 1, 3, 1 do
					copyVertex(projectedPoints[i], projected[face[i]])
					copyVertex(uvPoints[i], uv[face[i + 3]])
				end
			end
			
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
local zKeyDown = false

local function checkScreen()	
	if userInputService:IsKeyDown(Enum.KeyCode.Z) then
		if not zKeyDown then
			zKeyDown = true

			if screenMode == 0 then
				workspaceCamera.CameraType = Enum.CameraType.Scriptable
				workspaceCamera.CFrame = pixels[1][1].CFrame:Lerp(pixels[WIDTH][HEIGHT].CFrame, 0.5) + newVector(0, 0, WIDTH * 0.25)
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
			zBuffer[x][y] = -HUGE
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
	
	testSpinThings(deltaTime)
		
	renderObjects(objects, camera)
end

local pixelFolder = newInstance("Folder")

pixelFolder.Name = "PixelFolder"
pixelFolder.Parent = workspace

local partSize = newVector(0.5, 0.5, 0.5)

for x = 1, WIDTH, 1 do
	pixels[x] = {}
	zBuffer[x] = {}

	for y = 1, HEIGHT, 1 do
		local part = newInstance("Part")
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
		zBuffer[x][y] = -HUGE
	end
end

insertTestObjects()

local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")

while player.Character == nil do
	runService.RenderStepped:Wait()
end

local lastTime = osClock()

while true do
	runService.RenderStepped:Wait()
	deltaTime = osClock() - lastTime
	lastTime = osClock()
	checkScreen()
	mainLoop()
end
