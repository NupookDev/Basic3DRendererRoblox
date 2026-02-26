local module = {}
local library = require(script.Parent.Library)
local objectsModule = require(script.Parent.Objects)

module.ScreenMode = {
	ROBLOX = 0,
	ENGINE = 1
}

export type camera = {
	position: { number },
	rotation: { { number } }
}

type inBoundData = {
	clip: { number },
	uv: { number },
	projected: { number }
}

type outBoundData = {
	clip: { number },
	uv: { number }
}

local WIDTH = 240
local HEIGHT = 135
local ASPECT_RATIO = WIDTH / HEIGHT
local ASPECT_RATIO_INV = 1 / ASPECT_RATIO

local NEAR_PLANE_Z = -1
local INV_NEAR_PLANE_Z = 1 / -NEAR_PLANE_Z

local userInputService = game:GetService("UserInputService")
local workspaceCamera = workspace.Camera

local pixels: { { Part } } = {}
local zBuffer: { { number } } = {}

module.screenMode = module.ScreenMode.ROBLOX

local function getLightDot(vertex0: { number }, vertex1: { number }, vertex2: { number }): number
	local crossProduct: { number } = {}

	library.cross(crossProduct, { vertex1[1] - vertex0[1], vertex1[2] - vertex0[2], vertex1[3] - vertex0[3] }, { vertex2[1] - vertex0[1], vertex2[2] - vertex0[2], vertex2[3] - vertex0[3] })

	if not library.normalize3D(crossProduct) then
		return 0
	end
	
	local lightDot = library.dot3D(crossProduct, { -0.7103532724176078, 0.7038453156522361, 0 })

	if lightDot < 0 then
		lightDot = -lightDot
	end

	lightDot = (lightDot + 1) * 0.5
	return lightDot
end

local function putPixel(x: number, y: number, color: { number })	
	pixels[x + 1][y + 1].Color = Color3.fromRGB(color[1], color[2], color[3])
end

local function getTexturePixel(result: { number }, texture: objectsModule.texture, u: number, v: number): { number }
	local xy = (math.round(u * (texture.size[1] - 1)) + (math.round(v * (texture.size[2] - 1)) * texture.size[1])) * 3

	result[1] = buffer.readu8(texture.data, xy)
	result[2] = buffer.readu8(texture.data, xy + 1)
	result[3] = buffer.readu8(texture.data, xy + 2)
end

--[[
	echelon form
	[ a, b, c ]
	[ d, e, f ]
]]
local function computeBarry(result: { number }, matrix: { { number } }): boolean
	local a, b = matrix[1][1], matrix[1][2]
	local c, d = matrix[2][1], matrix[2][2]

	local detInv = (a * d) - (c * b)

	if detInv == 0 then
		return false
	end

	detInv = 1 / detInv

	local e, f = matrix[1][3], matrix[2][3]

	result[2] = ((a * f) - (c * e)) * detInv

	if result[2] < 0 then
		return false
	end

	result[1] = ((d * e) - (b * f)) * detInv

	if result[1] < 0 then
		return false
	end

	result[3] = 1 - result[1] - result[2]

	if result[3] < 0 then
		return false
	end

	return true
end

local function drawTriangle(projected: { { number } }, UVCoords: { { number } }, worldSpace: { { number } }, texture: objectsModule.texture, color: { number })	
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
	
	local lightDot = getLightDot(worldSpace[1], worldSpace[2], worldSpace[3])
	local projected0: { { number } }, projected1: { { number } }, projected2: { { number } } = projected[1], projected[2], projected[3]
	local barryMatrix: { { number } } = { {}, {} }

	barryMatrix[1][1], barryMatrix[1][2] = projected0[1] - projected2[1], projected1[1] - projected2[1]
	barryMatrix[2][1], barryMatrix[2][2] = projected0[2] - projected2[2], projected1[2] - projected2[2]

	if texture then
		for y = yMin, yMax, 1 do
			for x = xMin, xMax, 1 do
				barryMatrix[1][3], barryMatrix[2][3] = x - projected2[1], y - projected2[2]
				
				local barryResult: { number } = {}
				
				if not computeBarry(barryResult, barryMatrix) then
					continue
				end

				local perspectiveCorrectW = 1 / ((barryResult[1] * projected0[3]) + (barryResult[2] * projected1[3]) + (barryResult[3] * projected2[3]))
				local correctZ = -perspectiveCorrectW
				local luaX, luaY = x + 1, y + 1

				if correctZ <= zBuffer[luaX][luaY] then
					continue
				end

				zBuffer[luaX][luaY] = correctZ

				local perspectiveU = barryResult[1] * projected0[3]
				local perspectiveV = barryResult[2] * projected1[3]
				local perspectiveW = barryResult[3] * projected2[3]
				
				local ut = ((perspectiveU * UVCoords[1][1]) + (perspectiveV * UVCoords[2][1]) + (perspectiveW * UVCoords[3][1])) * perspectiveCorrectW
				local vt = ((perspectiveU * UVCoords[1][2]) + (perspectiveV * UVCoords[2][2]) + (perspectiveW * UVCoords[3][2])) * perspectiveCorrectW
				
				local texturePixel: { number } = {}
				
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
			barryMatrix[1][3], barryMatrix[2][3] = x - projected2[1], y - projected2[2]
			
			local barryResult: { number } = {}
			
			if not computeBarry(barryResult, barryMatrix) then
				continue
			end

			local correctZ = 1 / -((barryResult[1] * projected0[3]) + (barryResult[2] * projected1[3]) + (barryResult[3] * projected2[3]))
			local luaX, luaY = x + 1, y + 1

			if correctZ <= zBuffer[luaX][luaY] then
				continue
			end

			zBuffer[luaX][luaY] = correctZ
			
			putPixel(x, y, {
				color[1] * lightDot,
				color[2] * lightDot,
				color[3] * lightDot
			})
		end
	end
end

local function clipToScreenX(x: number, wInv: number): number
	return math.floor(((x * ASPECT_RATIO_INV * wInv) + 1) * 0.5 * (WIDTH - 1))
end

local function clipToScreenY(y: number, wInv: number): number
	return math.floor((1 - (y * wInv)) * 0.5 * (HEIGHT - 1))
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

local function renderObjects(objects: {}, objectCount: number, camera: {})
	local transposedRotation: { { number } } = { {}, {}, {} }

	for i = 1, 3, 1 do
		for j = 1, 3, 1 do
			transposedRotation[i][j] = camera.rotation[j][i]
		end
	end

	for i = 1, objectCount, 1 do
		local object: objectsModule.object = objects[i]
		
		local worldSpace: { { number } } = {}
		local clipspace: { { number } } = {}
		local projected: { { number } } = {}

		for i = 1, object.vertexCount, 1 do
			local vertex: { number } = {}
			
			vertex[1] = object.verticies[i][1]
			vertex[2] = object.verticies[i][2]
			vertex[3] = object.verticies[i][3]

			library.rotateVertex(vertex, object.rotation)
			vertex[1] += object.position[1]
			vertex[2] += object.position[2]
			vertex[3] += object.position[3]
			
			worldSpace[i] = {}
			library.copyVertex(worldSpace[i], vertex)

			vertex[1] -= camera.position[1]
			vertex[2] -= camera.position[2]
			vertex[3] -= camera.position[3]
			library.rotateVertex(vertex, transposedRotation)
			
			clipspace[i] = {}
			library.copyVertex(clipspace[i], vertex)
			
			if vertex[3] <= NEAR_PLANE_Z then
				local wInv = 1 / -vertex[3]
				
				projected[i] = { clipToScreenX(vertex[1], wInv), clipToScreenY(vertex[2], wInv), wInv }
			else
				projected[i] = 0
			end
		end

		for i = 1, object.faceCount, 1 do
			local face: { number } = object.faces[i]
			local outBounds: { outBoundData } = { {}, {}, {} }
			local inBounds: { inBoundData } = { {}, {}, {} }
			local outBoundsCount, inBoundsCount = 0, 0

			for i = 1, 3, 1 do
				if projected[face[i]] == 0 then
					outBoundsCount += 1
					outBounds[outBoundsCount].clip = clipspace[face[i]]
					outBounds[outBoundsCount].uv = object.uv[face[i + 3]]
				else
					inBoundsCount += 1
					inBounds[inBoundsCount].clip = clipspace[face[i]]
					inBounds[inBoundsCount].uv = object.uv[face[i + 3]]
					inBounds[inBoundsCount].projected = projected[face[i]]
				end
			end

			if outBoundsCount == 3 then
				continue
			end
			
			local worldSpaceResult: { { number } } = { {}, {}, {} }
			
			for i = 1, 3, 1 do
				library.copyVertex(worldSpaceResult[i], worldSpace[face[i]])
			end
			
			local projectedResult: { { number } } = { {}, {}, {} }
			local uvResult: { { number } } = { {}, {}, {} }

			if outBoundsCount == 2 then
				library.copyVertex(projectedResult[1], inBounds[1].projected)
				library.copyVertex(uvResult[1], inBounds[1].uv)

				getNearClippedVertex(projectedResult[2], uvResult[2], inBounds[1].clip, outBounds[1].clip, inBounds[1].uv, outBounds[1].uv)
				getNearClippedVertex(projectedResult[3], uvResult[3], inBounds[1].clip, outBounds[2].clip, inBounds[1].uv, outBounds[2].uv)
			elseif outBoundsCount == 1 then
				for i = 1, 2, 1 do
					library.copyVertex(projectedResult[i], inBounds[i].projected)
					library.copyVertex(uvResult[i], inBounds[i].uv)
				end

				getNearClippedVertex(projectedResult[3], uvResult[3], inBounds[1].clip, outBounds[1].clip, inBounds[1].uv, outBounds[1].uv)

				drawTriangle(
					projectedResult,
					uvResult,
					worldSpaceResult,
					object.texture,
					object.color
				)

				getNearClippedVertex(projectedResult[1], uvResult[1], inBounds[2].clip, outBounds[1].clip, inBounds[2].uv, outBounds[1].uv)
			else
				for i = 1, 3, 1 do
					library.copyVertex(projectedResult[i], projected[face[i]])
					library.copyVertex(uvResult[i], object.uv[face[i + 3]])
				end
			end

			drawTriangle(
				projectedResult,
				uvResult,
				worldSpaceResult,
				object.texture,
				object.color
			)
		end
	end
end

local function onEnterScreen(actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end
	
	if module.screenMode == module.ScreenMode.ROBLOX then
		workspaceCamera.CameraType = Enum.CameraType.Scriptable
		workspaceCamera.CFrame = pixels[1][1].CFrame:Lerp(pixels[WIDTH][HEIGHT].CFrame, 0.5) + Vector3.new(0, 0, WIDTH * 0.25)
		userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		userInputService.MouseIconEnabled = false
		module.screenMode = module.ScreenMode.ENGINE
	else
		workspaceCamera.CameraType = Enum.CameraType.Custom
		userInputService.MouseBehavior = Enum.MouseBehavior.Default
		userInputService.MouseIconEnabled = true
		module.screenMode = module.ScreenMode.ROBLOX
	end
end

function module.routine(objects: { objectsModule.object }, objectCount: number, camera: camera)
	for x = 1, WIDTH, 1 do
		for y = 1, HEIGHT, 1 do
			pixels[x][y].Color = Color3.fromRGB(0, 0, 0)
			zBuffer[x][y] = -math.huge
		end
	end
	
	renderObjects(objects, objectCount, camera)
end

function module.screenToWorldPosition(result: { number }, camera: camera, x: number, y: number): boolean
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT then
		return false
	end
	
	local z = zBuffer[x][y]
	
	if z == -math.huge then
		return false
	end
	
	result[1] = ((x / (WIDTH - 1) * 2) - 1) * ASPECT_RATIO * z
	result[2] = ((y / (HEIGHT - 1) * 2) - 1) * -z
	result[3] = z
	
	library.rotateVertex(result, camera.rotation)
	result[1] += camera.position[1]
	result[2] += camera.position[2]
	result[3] += camera.position[3]
	
	return true
end

function module.initScreen()
	local pixelFolder = Instance.new("Folder")

	pixelFolder.Name = "PixelFolder"
	pixelFolder.Parent = workspace

	for x = 1, WIDTH, 1 do
		pixels[x] = {}
		zBuffer[x] = {}

		for y = 1, HEIGHT, 1 do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.Size = Vector3.new(0.5, 0.5, 0.5)
			part.Position = Vector3.new(x * 0.5, (HEIGHT - y) * 0.5, 0)
			part.Parent = pixelFolder
			part.Name = string.format("%d:%d", x, y)
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			pixels[x][y] = part
			zBuffer[x][y] = -math.huge
		end
	end
	
	game:GetService("ContextActionService"):BindAction("enterScreen", onEnterScreen, false, Enum.KeyCode.Z)
end

return module
