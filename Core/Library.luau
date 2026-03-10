local module = {}

function module.copyVertex(vertex0: { number }, vertex1: { number })
	vertex0[1] = vertex1[1]
	vertex0[2] = vertex1[2]
	vertex0[3] = vertex1[3]
end

function module.addVertex(vertex0: { number }, vertex1: { number })
	vertex0[1] += vertex1[1]
	vertex0[2] += vertex1[2]
	vertex0[3] += vertex1[3]
end

function module.subtractVertex(vertex0: { number }, vertex1: { number })
	vertex0[1] -= vertex1[1]
	vertex0[2] -= vertex1[2]
	vertex0[3] -= vertex1[3]
end

function module.scaleVertex(vertex: { number }, scale: number)
	vertex[1] *= scale
	vertex[2] *= scale
	vertex[3] *= scale
end

function module.dot3D(vertex0: { number }, vertex1: { number }): number
	return (vertex0[1] * vertex1[1]) + (vertex0[2] * vertex1[2]) + (vertex0[3] * vertex1[3])
end

function module.cross(result: { number }, vertex0: { number }, vertex1: { number })
	result[1] = (vertex0[2] * vertex1[3]) - (vertex1[2] * vertex0[3])
	result[2] = (vertex0[1] * vertex1[3]) - (vertex1[1] * vertex0[3])
	result[3] = (vertex0[1] * vertex1[2]) - (vertex1[1] * vertex0[2])
end

function module.multiplyMatrix(matrix0: { { number } }, matrix1: { { number } })
	for i = 1, 3, 1 do
		local x, y, z = matrix0[i][1], matrix0[i][2], matrix0[i][3]

		matrix0[i][1] = (x * matrix1[1][1]) + (y * matrix1[2][1]) + (z * matrix1[3][1])
		matrix0[i][2] = (x * matrix1[1][2]) + (y * matrix1[2][2]) + (z * matrix1[3][2])
		matrix0[i][3] = (x * matrix1[1][3]) + (y * matrix1[2][3]) + (z * matrix1[3][3])
	end
end

function module.rotateVertex(vertex: { number }, rotationMatrix: { { number } })
	local x, y, z = vertex[1], vertex[2], vertex[3]
	
	vertex[1] = (x * rotationMatrix[1][1]) + (y * rotationMatrix[1][2]) + (z * rotationMatrix[1][3])
	vertex[2] = (x * rotationMatrix[2][1]) + (y * rotationMatrix[2][2]) + (z * rotationMatrix[2][3])
	vertex[3] = (x * rotationMatrix[3][1]) + (y * rotationMatrix[3][2]) + (z * rotationMatrix[3][3])
end

function module.normalize3D(vec: { number }): boolean
	local magnitudeSquared = (vec[1] * vec[1]) + (vec[2] * vec[2]) + (vec[3] * vec[3])
	
	if magnitudeSquared == 0 then
		return false
	end
	
	local magnitudeInv = 1 / math.sqrt(magnitudeSquared)
	
	vec[1] *= magnitudeInv
	vec[2] *= magnitudeInv
	vec[3] *= magnitudeInv
	
	return true
end

return module
