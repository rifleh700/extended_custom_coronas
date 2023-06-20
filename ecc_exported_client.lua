
function createCorona(x, y, z, size, r, g, b, a, texture)
	if not scheck("n[3],?n[5],?u:element:texture") then return false end

	size = math.max(0, size)
	r = r and math.floor(math.clamp(r, 0, 255)) or 255
	g = g and math.floor(math.clamp(g, 0, 255)) or 0
	b = b and math.floor(math.clamp(b, 0, 255)) or 0
	a = a and math.floor(math.clamp(a, 0, 255)) or 255
	texture = texture or DEFAULT_TEXTURE
	
	return ECC.create(texture, x, y, z, 0, 0, 0, size, r, g, b, a, false)
end

function createDirectionalCorona(x, y, z, dirX, dirY, dirZ, size, r, g, b, a, texture)
	if not scheck("n[6],?n[5],?u:element:texture") then return false end

	size = math.max(0, size)
	r = r and math.floor(math.clamp(r, 0, 255)) or 255
	g = g and math.floor(math.clamp(g, 0, 255)) or 0
	b = b and math.floor(math.clamp(b, 0, 255)) or 0
	a = a and math.floor(math.clamp(a, 0, 255)) or 255
	texture = texture or DEFAULT_TEXTURE

	return ECC.create(texture, x, y, z, dirX, dirY, dirZ, size, r, g, b, a, true)
end

function isCoronaDirectional(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.directional
end

function setCoronaTexture(corona, texture)
	if not scheck("u:element:corona,?u:element:texture") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	texture = texture or DEFAULT_TEXTURE
	if data.texture == texture then return false end

	data.texture = texture
	addEventHandler("onClientElementDestroy", texture, ECC.onTextureDestroy, false)

	return true
end

function getCoronaTexture(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if data.texture == DEFAULT_TEXTURE then return nil end
	return data.texture
end

function setCoronaPosition(corona, x, y, z)
	if not scheck("u:element:corona,n[3]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end

	data.pos = {x, y, z}

	return true
end

function getCoronaPosition(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.pos[1], data.pos[2], data.pos[3]
end

function setCoronaRotation(corona, rotX, rotY, rotZ)
	if not scheck("u:element:corona,n[3]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.directional then return false end
	if data.attachedTo then return false end

	data.dir = {rotationToDirection(rotX, rotY, rotZ)}

	return true
end

function getCoronaRotation(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.directional then return 0, 0, 0 end

	return directionToRotation(data.dir[1], data.dir[2], data.dir[3])
end

function setCoronaDirection(corona, dirX, dirY, dirZ)
	if not scheck("u:element:corona,n[3]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.directional then return false end
	if data.attachedTo then return false end

	data.dir = {dirX, dirY, dirZ}

	return true
end

function getCoronaDirection(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.directional then return 0, 0, 0 end

	return data.dir[1], data.dir[2], data.dir[3]
end

function setCoronaInterior(corona, int)
	if not scheck("u:element:corona,n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end
	if data.int == int then return false end

	data.int = math.clamp(math.floor(int), 0, 255)

	return true
end

function getCoronaInterior(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.int
end

function setCoronaDimension(corona, dim)
	if not scheck("u:element:corona,n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end
	if data.dim == dim then return false end

	data.dim = math.clamp(math.floor(dim), -1, 65535)

	return true
end

function getCoronaDimension(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.dim
end

function attachCorona(corona, attachedTo, offX, offY, offZ, offRotX, offRotY, offRotZ)
	if not scheck("u:element:corona,u:element,?n[6]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.offsets = {
		offX or 0, offY or 0, offZ or 0,
		offRotX or 0, offRotY or 0, offRotZ or 0
	}
	data.attachedTo = attachedTo
	addEventHandler("onClientElementDestroy", attachedTo, ECC.onAttachedToDestroy, false)

	return true
end

function setCoronaAttachedOffsets(corona, offX, offY, offZ, offRotX, offRotY, offRotZ)
	if not scheck("u:element:corona,n[3],?n[3]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.attachedTo then return false end

	data.offsets = {
		offX, offY, offZ,
		offRotX or 0, offRotY or 0, offRotZ or 0
	}

	return true
end

function getCoronaAttachedTo(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.attachedTo
end

function getCoronaAttachedOffsets(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if not data.attachedTo then return false end
	
	local off = data.offsets
	return off[1], off[2], off[3], off[4], off[5], off[6]
end

function detachCorona(corona, element)
	if not scheck("u:element:corona,?u:element") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if not data.attachedTo then return false end

	element = element or data.attachedTo
	if element ~= data.attachedTo then return false end

	data.attachedTo = nil

	return true
end

function setCoronaSize(corona, size)
	if not scheck("u:element:corona,n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	size = math.max(0, size)
	if data.size == size then return false end

	data.size = size

	return true
end

function getCoronaSize(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.size
end

function setCoronaColor(corona, r, g, b, a)
	if not scheck("u:element:corona,n[3],?n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.color[1] = math.floor(math.clamp(r, 0, 255))
	data.color[2] = math.floor(math.clamp(g, 0, 255))
	data.color[3] = math.floor(math.clamp(b, 0, 255))
	data.color[4] = a and math.floor(math.clamp(a, 0, 255)) or data.color[4]

	return true
end

function getCoronaColor(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.color[1], data.color[2], data.color[3], data.color[4]
end

function setCoronaAlpha(corona, a)
	if not scheck("u:element:corona,n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.color[4] = math.floor(math.clamp(a, 0, 255))

	return true
end

function getCoronaAlpha(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.color[4]
end

function setCoronaDepthBias(corona, depthBias)
	if not scheck("u:element:corona,?n") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	
	data.depthBias = depthBias or math.min(data.size, 1)

	return true
end

function getCoronaDepthBias(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	
	return data.depthBias
end

function setDirectionalCoronaCone(corona, outerAngle, innerAngle)
	if not scheck("u:element:corona,n[2]") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	
	outerAngle = math.clamp(outerAngle, 0, 179)
	innerAngle = math.clamp(innerAngle, 0, outerAngle)

	data.cone = {
		math.rad(outerAngle*0.5),
		math.rad(innerAngle*0.5),
	}

	return true
end

function getDirectionalCoronaCone(corona)
	if not scheck("u:element:corona") then return false end

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return math.deg(data.cone[1]*2), math.deg(data.cone[2]*2)
end

function setCoronasDepthBiasEnabled(state)
	if not scheck("b") then return false end

	if ECC.shaderSettings.depthBiasEnabled == state then return false end

	ECC.shaderSettings.depthBiasEnabled = state

	return true
end

function getCoronasDepthBiasEnabled()
	
	return ECC.shaderSettings.depthBiasEnabled
end

function setCoronasFadeDistance(dist1, dist2)
	if not scheck("?n[2]") then return false end

	local fadeDistance = {} 
	if (not dist1) and (not dist2) then
		fadeDistance = SHADER_DEFAULT_FADE_DISTANCE
	else
		fadeDistance = {dist1 or currentFadeDistance[1], dist2 or currentFadeDistance[2]}
		if fadeDistance[1] < fadeDistance[2] then return warn("first value must be bigger", 2) and false end
	end

	local currentFadeDistance = ECC.shaderSettings.fadeDistance
	if currentFadeDistance[1] == fadeDistance[1] and currentFadeDistance[2] == fadeDistance[2] then return false end

	ECC.shaderSettings.fadeDistance = fadeDistance
	ECC.updateShadersSettings()
	
	return true
end

function getCoronasFadeDistance()
	
	return ECC.shaderSettings.fadeDistance[1], ECC.shaderSettings.fadeDistance[2] 
end