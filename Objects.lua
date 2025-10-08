local module = {}

local createBuffer, writeu8 = buffer.create, buffer.writeu8

local imported = game:GetService("ReplicatedStorage").Imported
local floppa = require(imported.Floppa)
local koi = require(imported.KoiFish)
local teddy = require(imported.Teddy)

local testTexture = { size = { 10, 10 }, data = nil }

module.objectCount = 1

module.objects = {
	{
		vertexCount = 5,
		verticies = {
			{ 1, -1, 1 },
			{ -1, -1, 1 },
			{ -1, -1, -1 },
			{ 1, -1, -1 },
			{ 0, 1, 0 }
		},
		position = { 3, 0, -2 },
		rotation = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		},
		faceCount = 6,
		faces = {
			{ 1, 2, 5, 1, 2, 3 }, -- { vertex0, vertex1, vertex2, uv0, uv1, uv2 }
			{ 2, 3, 5, 1, 2, 3 },
			{ 3, 4, 5, 1, 2, 3 },
			{ 4, 1, 5, 1, 2, 3 },
			{ 1, 2, 4, 4, 4, 4 },
			{ 2, 3, 4, 4, 4, 4 }
		},
		uv = {
			{ 1, 1 },
			{ 0, 1 },
			{ 0.5, 0 },
			{ 0, 0 }
		},
		texture = testTexture
	}
}

local function createBox(position: { number }, size: { number }): {}
	local sizeXHalf = size[1] * 0.5
	local sizeYHalf = size[2] * 0.5
	local sizeZHalf = size[3] * 0.5
	
	module.objectCount += 1
	
	module.objects[module.objectCount] =  {
		position = { position[1], position[2], position[3] },
		vertexCount = 8,
		verticies = {
			{ sizeXHalf, -sizeYHalf, sizeZHalf },
			{ -sizeXHalf, -sizeYHalf, sizeZHalf },
			{ -sizeXHalf, sizeYHalf, sizeZHalf },
			{ -sizeXHalf, -sizeYHalf, -sizeZHalf },
			{ -sizeXHalf, sizeYHalf, -sizeZHalf },
			{ sizeXHalf, -sizeYHalf, -sizeZHalf },
			{ sizeXHalf, sizeYHalf, -sizeZHalf },
			{ sizeXHalf, sizeYHalf, sizeZHalf }
		},
		rotation = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		},
		faceCount = 12,
		faces = {
			{ 1, 2, 3, 1, 2, 3 },
			{ 1, 3, 8, 1, 3, 4 },
			{ 2, 4, 5, 1, 2, 3 },
			{ 2, 5, 3, 1, 3, 4 },
			{ 4, 6, 7, 1, 2, 3 },
			{ 4, 7, 5, 1, 3, 4 },
			{ 6, 1, 8, 1, 2, 3 },
			{ 6, 8, 7, 1, 3, 4 },
			{ 1, 2, 4, 3, 3, 3 },
			{ 1, 4, 6, 3, 3, 3 },
			{ 3, 5, 8, 3, 3, 3 },
			{ 8, 5, 7, 3, 3, 3 }
		},
		uv = {
			{ 1, 1 },
			{ 0, 1 },
			{ 0, 0 },
			{ 1, 0 }
		},
		texture = nil,
		color = { 255, 255, 255 }
	}
	
	return module.objects[module.objectCount]
end

local function createCone(position: { number }, height: number, baseRadius: number)
	local cone = {
		position = { position[1], position[2], position[3] },
		vertexCount = 3,
		verticies = {
			{ 0, 0, 0 },
			{ 0, height, 0 },
			{ baseRadius, 0, 0 }
		},
		rotation = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		},
		faceCount = 0,
		faces = {},
		uv = { { 0, 0 } },
		texture = nil,
		color = { 255, 255, 255 }
	}
	
	local lastX, lastZ = baseRadius, 0
	
	for i = 1, 9, 1 do
		local x = (lastX * 0.809) - (lastZ * 0.588)
		local z = (lastX * 0.588) + (lastZ * 0.809)	
		
		lastX = x
		lastZ = z

		local lastVertexIndex = cone.vertexCount
		
		cone.vertexCount += 1
		cone.verticies[cone.vertexCount] = { x, 0, z }

		cone.faceCount += 1
		cone.faces[cone.faceCount] = { 1, lastVertexIndex, cone.vertexCount, 1, 1, 1 }

		cone.faceCount += 1
		cone.faces[cone.faceCount] = { 2, lastVertexIndex, cone.vertexCount, 1, 1, 1 }
	end
	
	cone.faceCount += 1
	cone.faces[cone.faceCount] = { 1, 3, cone.vertexCount, 1, 1, 1 }
	
	cone.faceCount += 1
	cone.faces[cone.faceCount] = { 2, 3, cone.vertexCount, 1, 1, 1 }
	
	module.objectCount += 1
	module.objects[module.objectCount] = cone
	
	return cone
end

local function setColor(object: {}, color: { number })
	object.color[1] = color[1]
	object.color[2] = color[2]
	object.color[3] = color[3]
end

module.insertTestObjects = function()
	local smile = {
		{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
		{ 0, 0, 0, 0, 1, 1, 0, 1, 0, 0 },
		{ 0, 0, 0, 0, 1, 1, 0, 0, 1, 0 },
		{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 },
		{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 },
		{ 0, 0, 0, 0, 1, 1, 0, 0, 1, 0 },
		{ 0, 0, 0, 0, 1, 1, 0, 1, 0, 0 },
		{ 0, 0, 0, 0, 0, 0, 1, 0, 0, 0 },
		{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	}

	testTexture.data = createBuffer(300)

	for x = 1, testTexture.size[1], 1 do
		for y = 1, testTexture.size[2], 1 do	
			if smile[x][y] == 0 then
				local xy = ((x - 1) + ((y - 1) * testTexture.size[1])) * 3
				
				writeu8(testTexture.data, xy, 255)
				writeu8(testTexture.data, xy + 1, 255)
				writeu8(testTexture.data, xy + 2, 255)
			end
		end
	end
	
	createBox({ 0, 0, 0 }, { 2, 2, 2 }).texture = testTexture
	
	local skinColor = { 245, 205, 48 }
	local legColor = { 164, 189, 71 }
	
	setColor(createBox({ 10, 1.5, 0 }, { 1, 1, 1 }), skinColor)
	setColor(createBox({ 10, 0, 0 }, { 2, 2, 1 }), { 13, 105, 172 })
	setColor(createBox({ 11.5, 0, 0 }, { 1, 2, 1 }), skinColor)
	setColor(createBox({ 8.5, 0, 0 }, { 1, 2, 1 }), skinColor)
	setColor(createBox({ 10.5, -2, 0 }, { 1, 2, 1 }), legColor)
	setColor(createBox({ 9.5, -2, 0 }, { 1, 2, 1 }), legColor)
	setColor(createCone({ 5, 0, 5 }, 5, 2), { 255, 255, 0 })
	
	module.objectCount += 1
	module.objects[module.objectCount] = floppa
	
	module.objectCount += 1
	module.objects[module.objectCount] = koi
	
	module.objectCount += 1
	module.objects[module.objectCount] = teddy
end

return module
