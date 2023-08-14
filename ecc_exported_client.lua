
---@param ctype string Type of the corona. Valid values are "simple", "directional", "nomat", "soft".
function createCustomCorona(x, y, z, rx, ry, rz, ctype, size, r, g, b, a, texture)

	ctype = ctype or CORONA_TYPE_SIMPLE
	if ctype ~= CORONA_TYPE_SIMPLE and ctype ~= CORONA_TYPE_DIRECTIONAL and ctype ~= CORONA_TYPE_NOMAT then
		return warn("illegal corona type" ,2) and false
	end

	local dx, dy, dz = getDirectionFromRotation(rx or 0, ry or 0, rz or 0)
	size = math.max(0, size or 1)
	r = r and math.floor(math.clamp(r, 0, 255)) or 255
	g = g and math.floor(math.clamp(g, 0, 255)) or 0
	b = b and math.floor(math.clamp(b, 0, 255)) or 0
	a = a and math.floor(math.clamp(a, 0, 255)) or 255
	texture = texture or TEXTURE_DEFAULT

	return ECC.create(ctype, texture, x, y, z, dx, dy, dz, size, r, g, b, a)
end

function getCustomCoronaType(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.ctype
end

function setCustomCoronaTexture(corona, texture)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	texture = texture or TEXTURE_DEFAULT
	if data.texture == texture then return false end

	data.texture = texture
	addEventHandler("onClientElementDestroy", texture, ECC.onTextureDestroy, false)

	return true
end

function getCustomCoronaTexture(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if data.texture == TEXTURE_DEFAULT then return nil end
	return data.texture
end

function setCustomCoronaPosition(corona, x, y, z)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end

	data.pos = {x, y, z}

	return true
end

function getCustomCoronaPosition(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.pos[1], data.pos[2], data.pos[3]
end

function setCustomCoronaRotation(corona, rotX, rotY, rotZ)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end

	data.dir = {getDirectionFromRotation(rotX, rotY, rotZ)}

	return true
end

function getCustomCoronaRotation(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return getRotationFromDirection(data.dir[1], data.dir[2], data.dir[3])
end

function setCustomCoronaInterior(corona, int)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end
	if data.int == int then return false end

	data.int = math.clamp(math.floor(int), 0, 255)

	return true
end

function getCustomCoronaInterior(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.int
end

function setCustomCoronaDimension(corona, dim)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.attachedTo then return false end
	if data.dim == dim then return false end

	data.dim = math.clamp(math.floor(dim), -1, 65535)

	return true
end

function getCustomCoronaDimension(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.dim
end

function attachCustomCorona(corona, attachedTo, offX, offY, offZ, offRotX, offRotY, offRotZ)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.offsets = {
		offX or 0, offY or 0, offZ or 0,
		getDirectionFromRotation(offRotX or 0, offRotY or 0, offRotZ or 0)
	}
	data.attachedTo = attachedTo
	addEventHandler("onClientElementDestroy", attachedTo, ECC.onAttachedToDestroy, false)

	return true
end

function detachCustomCorona(corona, element)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if not data.attachedTo then return false end

	element = element or data.attachedTo
	if element ~= data.attachedTo then return false end

	data.attachedTo = nil

	return true
end

function getCustomCoronaAttachedTo(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.attachedTo
end

function setCustomCoronaAttachedOffsets(corona, offX, offY, offZ, offRotX, offRotY, offRotZ)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if not data.attachedTo then return false end

	data.offsets = {
		offX, offY, offZ,
		getDirectionFromRotation(offRotX or 0, offRotY or 0, offRotZ or 0)
	}

	return true
end

function getCustomCoronaAttachedOffsets(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	if not data.attachedTo then return false end
	
	local ox, oy, oz = data.offsets[1], data.offsets[2], data.offsets[3]
	local orx, ory, orz = getRotationFromDirection(data.offsets[3], data.offsets[4], data.offsets[5])
	return ox, oy, oz, orx, ory, orz
end

function setCustomCoronaSize(corona, size)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	size = math.max(0, size)
	if data.size == size then return false end

	data.size = size

	return true
end

function getCustomCoronaSize(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.size
end

function setCustomCoronaColor(corona, r, g, b, a)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.color[1] = math.floor(math.clamp(r, 0, 255))
	data.color[2] = math.floor(math.clamp(g, 0, 255))
	data.color[3] = math.floor(math.clamp(b, 0, 255))
	data.color[4] = a and math.floor(math.clamp(a, 0, 255)) or data.color[4]

	return true
end

function getCustomCoronaColor(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.color[1], data.color[2], data.color[3], data.color[4]
end

function setCustomCoronaAlpha(corona, a)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.color[4] = math.floor(math.clamp(a, 0, 255))

	return true
end

function getCustomCoronaAlpha(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.color[4]
end

--- Only for "directional" type coronas.
--- Pass greater angles (180 is maximum)
---@param corona userdata the corona element
---@param outerAngle number outer angle (0 - 180)
---@param innerAngle number inner angle (0 - outerAngle)
function setCustomCoronaLightCone(corona, outerAngle, innerAngle)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.ctype ~= CORONA_TYPE_DIRECTIONAL then return false end
	
	outerAngle = math.clamp(outerAngle, 0, 179)
	innerAngle = math.clamp(innerAngle, 0, outerAngle)

	data.lightCone = {
		math.rad(outerAngle*0.5),
		math.rad(innerAngle*0.5),
	}

	return true
end

function getCustomCoronaLightCone(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end
	if data.ctype ~= CORONA_TYPE_DIRECTIONAL then return nil end

	return math.deg(data.lightCone[1]*2), math.deg(data.lightCone[2]*2)
end

--- Only for "nomat" type coronas
function setCustomCoronaLightAttenuationPower(corona, power)

	local data = ECC.coronasData[corona]
	if not data then error("bad argument #1 'corona' to 'setCustomCoronaLightAttenuationPower' (corona expected)", 2) end
	if power and type(power) ~= "number" then error("bad argument #2 'power' to 'setCustomCoronaLightAttenuationPower' (number expected)", 2) end

	if data.ctype ~= CORONA_TYPE_NOMAT then return false end

	data.attenuationPower = math.max(0, power or LIGHT_ATTENUATION_POWER_DEFAULT)

	return true
end

function getCustomCoronaLightAttenuationPower(corona)

	local data = ECC.coronasData[corona]
	if not data then error("bad argument #1 'corona' to 'getCustomCoronaLightAttenuationPower' (corona expected)", 2) end

	if data.ctype ~= CORONA_TYPE_NOMAT then return nil end

	return data.attenuationPower
end

function setCustomCoronaFadeDistance(corona, dist1, dist2)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	local fadeDist = {dist1 or FADE_DISTANCE_DEFAULT[1], dist2 or FADE_DISTANCE_DEFAULT[2]}
	fadeDist[2] = math.min(fadeDist[1], fadeDist[2])
	data.fadeDist = fadeDist
	
	return true
end

function getCustomCoronaFadeDistance(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.fadeDist[1], data.fadeDist[2]
end

function setCustomCoronaDepthBias(corona, depthBias)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	data.depthBias = math.clamp(depthBias or data.size, 0, data.size)

	return true
end

function getCustomCoronaDepthBias(corona)

	local data = ECC.coronasData[corona]
	if not data then return warn("invalid corona", 2) and false end

	return data.depthBias
end