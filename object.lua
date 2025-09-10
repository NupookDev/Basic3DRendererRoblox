local module = {}

local createBuffer, writeu8 = buffer.create, buffer.writeu8

function createBox(size: { number }): {}
	local sizeXHalf = size[1] * 0.5
	local sizeYHalf = size[2] * 0.5
	local sizeZHalf = size[3] * 0.5

	return {
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
		position = { 0, 0, 0 },
		rotation = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		},
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
end

local function createBoxWithPosition(position: { number }, size: { number })
	local box = createBox(size)

	box.position[1] = position[1]
	box.position[2] = position[2]
	box.position[3] = position[3]

	return box
end

local function setColor(object: {}, color: { number })
	object.color[1] = color[1]
	object.color[2] = color[2]
	object.color[3] = color[3]
end

local testTexture = { size = { 10, 10 }, data = nil }

local objects = {
	{
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

module.objects = objects

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

	local xy

	for x = 1, testTexture.size[1], 1 do
		for y = 1, testTexture.size[2], 1 do	
			if smile[x][y] == 0 then
				xy = ((x - 1) + ((y - 1) * testTexture.size[1])) * 3
				writeu8(testTexture.data, xy, 255)
				writeu8(testTexture.data, xy + 1, 255)
				writeu8(testTexture.data, xy + 2, 255)
			end
		end
	end
	
	objects[2] = createBox({ 2, 2, 2 })
	objects[2].texture = testTexture
	
	local skinColor = { 245, 205, 48 }
	local legColor = { 164, 189, 71 }

	objects[3] = createBoxWithPosition({ 10, 1.5, 0 }, { 1, 1, 1 })
	setColor(objects[3], skinColor)
	
	objects[4] = createBoxWithPosition({ 10, 0, 0 }, { 2, 2, 1 })
	setColor(objects[4], { 13, 105, 172 })
	
	objects[5] = createBoxWithPosition({ 11.5, 0, 0 }, { 1, 2, 1 })
	setColor(objects[5], skinColor)
	
	objects[6] = createBoxWithPosition({ 8.5, 0, 0 }, { 1, 2, 1 })
	setColor(objects[6], skinColor)
	
	objects[7] = createBoxWithPosition({ 10.5, -2, 0 }, { 1, 2, 1 })
	setColor(objects[7], legColor)
	
	objects[8] = createBoxWithPosition({ 9.5, -2, 0 }, { 1, 2, 1 })
	setColor(objects[8], legColor)
end

return module
