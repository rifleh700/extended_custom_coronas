
function math.clamp(value, min, max)

	return value < min and min or value > max and max or value
end

function getPositionFromElementOffsets(element, offX, offY, offZ)
	
	local m = getElementMatrix(element)
	return
		offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1],
		offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2],
		offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
end

function rotationToDirection(rotX, rotY, rotZ)
	
	rotX = math.rad(rotX)
	rotZ = math.rad(rotZ)
	return -math.cos(rotX) * math.sin(rotZ), math.cos(rotZ) * math.cos(rotX), math.sin(rotX)
end

function directionToRotation(dirX, dirY, dirZ)

	local rotX = math.deg(math.atan2(dirZ, getDistanceBetweenPoints2D(dirX, dirY, 0, 0)))
	local rotZ = -math.deg(math.atan2(dirX, dirY))
	return rotX, 0, rotZ
end

local _addEventHandler = addEventHandler
function addEventHandler(eventName, attachedTo, handlerFunction, ...)

	for i, f in ipairs(getEventHandlers(eventName, attachedTo)) do
		if f == handlerFunction then return false end
	end
	return _addEventHandler(eventName, attachedTo, handlerFunction, ...)
end