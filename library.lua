local module = {}

local sqrt = math.sqrt

module.dot3D = function(vertex0: { number }, vertex1: { number }): number
	return (vertex0[1] * vertex1[1]) + (vertex0[2] * vertex1[2]) + (vertex0[3] * vertex1[3])
end

module.cross = function(result: { number }, vertex0: { number }, vertex1: { number })
	result[1] = (vertex0[2] * vertex1[3]) - (vertex1[2] * vertex0[3])
	result[2] = (vertex0[1] * vertex1[3]) - (vertex1[1] * vertex0[3])
	result[3] = (vertex0[1] * vertex1[2]) - (vertex1[1] * vertex0[2])
end

module.multiplyMatrix = function(matrix0: { { number } }, matrix1: { { number } })
	local x, y, z

	for i = 1, 3, 1 do
		x, y, z = matrix0[i][1], matrix0[i][2], matrix0[i][3]

		matrix0[i][1] = (x * matrix1[1][1]) + (y * matrix1[2][1]) + (z * matrix1[3][1])
		matrix0[i][2] = (x * matrix1[1][2]) + (y * matrix1[2][2]) + (z * matrix1[3][2])
		matrix0[i][3] = (x * matrix1[1][3]) + (y * matrix1[2][3]) + (z * matrix1[3][3])
	end
end

module.rotateVertex = function(vertex: { number }, rotationMatrix: { { number } })
	local x, y, z = vertex[1], vertex[2], vertex[3]
	
	vertex[1] = (x * rotationMatrix[1][1]) + (y * rotationMatrix[1][2]) + (z * rotationMatrix[1][3])
	vertex[2] = (x * rotationMatrix[2][1]) + (y * rotationMatrix[2][2]) + (z * rotationMatrix[2][3])
	vertex[3] = (x * rotationMatrix[3][1]) + (y * rotationMatrix[3][2]) + (z * rotationMatrix[3][3])
end

module.normalize3D = function(vec: { number }): number
	local magnitudeSquared = (vec[1] * vec[1]) + (vec[2] * vec[2]) + (vec[3] * vec[3])
	
	if magnitudeSquared == 0 then
		return 0
	end
	
	local magnitudeInv = 1 / sqrt(magnitudeSquared)
	
	vec[1] *= magnitudeInv
	vec[2] *= magnitudeInv
	vec[3] *= magnitudeInv
	
	return 1
end

module.createBox = function(size: { number }): {}
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

module.computeBarry = function(result: { number }, matrix: { { number } }): number --echelon form
	local a, b = matrix[1][1], matrix[1][2]
	local c, d = matrix[2][1], matrix[2][2]
	
	local det = (a * d) - (c * b)
	
	if det == 0 then
		return 0
	end
	
	local detInv = 1 / det
	local e, f = matrix[1][3], matrix[2][3]
	
	result.v = ((a * f) - (c * e)) * detInv
	
	if result.v < 0 then
		return 0
	end
	
	result.u = ((d * e) - (b * f)) * detInv
	
	if result.u < 0 then
		return 0
	end
	
	result.w = 1 - result.u - result.v
	
	if result.w < 0 then
		return 0
	end
	
	return 1
end

return module
