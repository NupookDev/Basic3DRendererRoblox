local module = {}

export type texture = {
	size: { number },
	data: buffer
}

export type object = {
	position: { number },
	rotation: { { number } },
	verticies: { { number } },
	vertexCount: number,	
	faces: { { number } }, -- { { vertex0, vertex1, vertex2, uv0, uv1, uv2 }, ... }
	faceCount: number,
	uv: { { number } },
	texture: texture,
	color: { number }
}

module.objectCount = 1

local objects: { object } = {
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
			{ 1, 2, 5, 1, 2, 3 },
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
		texture = nil,
		color = { 255, 255, 255 }
	}
}

module.objects = objects

function module.insertObject(object: object)
	module.objectCount += 1
	module.objects[module.objectCount] = object
end

function module.removeObject(object: object)
	for i = 1, module.objectCount, 1 do
		if module.objects[i] == object then
			table.remove(module.objects, i)
			module.objectCount -= 1
			return
		end
	end
end

function module.insertPyramid(x: number, y: number, z: number, sizeX: number, sizeY: number, sizeZ: number): object
	local sizeXHalf, sizeYHalf, sizeZHalf = sizeX * 0.5, sizeY * 0.5, sizeZ * 0.5
	
	local pyramid: object = {
		vertexCount = 5,
		verticies = {
			{ sizeXHalf, -sizeYHalf, sizeZHalf },
			{ -sizeXHalf, -sizeYHalf, sizeZHalf },
			{ -sizeXHalf, -sizeYHalf, -sizeZHalf },
			{ sizeXHalf, -sizeYHalf, -sizeZHalf },
			{ 0, sizeYHalf, 0 }
		},
		position = { x, y, z },
		rotation = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		},
		faceCount = 6,
		faces = {
			{ 1, 2, 5, 1, 2, 3 },
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
		texture = nil,
		color = { 255, 255, 255 }
	}
	
	module.insertObject(pyramid)
	return pyramid
end

function module.insertBox(x: number, y: number, z: number, sizeX: number, sizeY: number, sizeZ: number): object
	local sizeXHalf = sizeX * 0.5
	local sizeYHalf = sizeY * 0.5
	local sizeZHalf = sizeZ * 0.5
	
	local box: object = {
		position = { x, y, z },
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
	
	module.insertObject(box)
	return box
end

function module.insertCone(x: number, y: number, z: number, height: number, baseRadius: number): object
	local cone: object = {
		position = { x, y, z },
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
	
	module.insertObject(cone)
	return cone
end

function module.insertCylinder(x: number, y: number, z: number, baseRadius: number, height: number)
	
end

return module
