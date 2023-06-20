
camera = getCamera()

DRAW_MAX = 255
DRAW_EDGE_TO_TOLERANCE = 0.35

SHADER_DEFAULT_DEPTH_BIAS_ENABLED = true
SHADER_DEFAULT_FADE_DISTANCE = {250, 150}
SHADER_DEFAULT_LIGHT_CONE = {math.pi/4, math.pi/12}

DEFAULT_TEXTURE_PATH = "textures/coronastar.png"
TEXTURE_FORMAT = "dxt1"
DEFAULT_TEXTURE = dxCreateTexture(DEFAULT_TEXTURE_PATH, TEXTURE_FORMAT, true, "clamp")

SHADER_PATH = "shaders/corona.fx"
SHADER = dxCreateShader(SHADER_PATH, 0, 0, false, "all")

DIRECTIONAL_SHADER_PATH = "shaders/corona_dir.fx"
SHADER_DIRECTIONAL = dxCreateShader(DIRECTIONAL_SHADER_PATH, 0, 0, false, "all")

ECC = {}

ECC.shaderSettings = {}
ECC.shaderSettings.depthBiasEnabled = SHADER_DEFAULT_DEPTH_BIAS_ENABLED
ECC.shaderSettings.fadeDistance = SHADER_DEFAULT_FADE_DISTANCE

ECC.coronasData = {}
ECC.coronasList = {}
ECC.drawData = {}
ECC.updateCoronasList = false

function ECC.getCallingResource()
	
	if not sourceResource then return nil end
	if type(sourceResource) ~= "userdata" then return nil end
	if getUserdataType(sourceResource) ~= "resource-data" then return nil end

	return sourceResource
end

function ECC.create(texture, x, y, z, dirX, dirY, dirZ, size, r, g, b, a, isDirectional)
	
	local data = {
		texture = texture,
		pos = {x, y, z},
		int = 0,
		dim = 0,
		dir = {dirX, dirY, dirZ},
		size = size,
		depthBias = math.min(size, 1),
		color = {r, g, b, a},
		cone = {SHADER_DEFAULT_LIGHT_CONE[1], SHADER_DEFAULT_LIGHT_CONE[2]},
		directional = isDirectional,
		parent = ECC.getCallingResource()
	}

	local element = createElement("corona")
	addEventHandler("onClientElementDestroy", element, ECC.onDestroy, false)
	addEventHandler("onClientElementDestroy", texture, ECC.onTextureDestroy, false)
	
	ECC.coronasData[element] = data
	ECC.updateCoronasList = true

	return element
end

function ECC.onDestroy()
	
	ECC.coronasData[this] = nil
	ECC.updateCoronasList = true

end

function ECC.onTextureDestroy()
		
	for corona, data in pairs(ECC.coronasData) do
		if data.texture == this then
			data.texture = DEFAULT_TEXTURE
		end
	end

end

function ECC.onAttachedToDestroy()
	
	for corona, data in pairs(ECC.coronasData) do
		if data.attachedTo == this then
			data.attachedTo = nil
		end
	end

end

addEventHandler("onClientResourceStop", root,
	function(stopped)

		for corona, data in pairs(ECC.coronasData) do
			if data.parent == stopped then
				destroyElement(corona)
			end
		end

	end,
	true,
	"low"
)

function ECC.updateShadersSettings()
	
	dxSetShaderValue(SHADER, "gDistFade", ECC.shaderSettings.fadeDistance)
	dxSetShaderValue(SHADER_DIRECTIONAL, "gDistFade", ECC.shaderSettings.fadeDistance)
	
	return true
end

addEventHandler("onClientPreRender", root,
	function()
		if not ECC.updateCoronasList then return end

		ECC.updateCoronasList = false

		local coronasList = {}
		local coronasListCount = 0
		for corona in pairs(ECC.coronasData) do
			coronasListCount = coronasListCount + 1
			coronasList[coronasListCount] = corona
		end
		ECC.coronasList = coronasList
		
	end,
	false,
	"low-1"
)

addEventHandler("onClientPreRender", root,
	function()

		local cx, cy, cz = getElementPosition(camera)
		local cint = getElementInterior(localPlayer)
		local cdim = getElementDimension(camera)

		local drawData = {}
		local drawDataCount = 0
		for i = 1, #ECC.coronasList do

			local data = ECC.coronasData[ECC.coronasList[i]]

			local attachedTo = data.attachedTo
			if attachedTo then
				local off = data.offsets
				data.pos = {getPositionFromElementOffsets(attachedTo, off[1], off[2], off[3])}

				local eRotX, eRotY, eRotZ = getElementRotation(attachedTo)
				data.dir = {rotationToDirection(eRotX + off[4], eRotY + off[5], eRotZ + off[6])}

				data.int = getElementInterior(attachedTo)
				data.dim = getElementDimension(attachedTo)
			end

			if data.int == cint and (data.dim == -1 or data.dim == cdim) then
				local camDist = getDistanceBetweenPoints3D(data.pos[1], data.pos[2], data.pos[3], cx, cy, cz)
				if camDist < ECC.shaderSettings.fadeDistance[1] then 
					
					drawDataCount = drawDataCount + 1
					drawData[drawDataCount] = {
						texture = data.texture,
						shader = data.directional and SHADER_DIRECTIONAL or SHADER,
						pos = data.pos,
						dir = data.dir,
						depthBias = ECC.shaderSettings.depthBiasEnabled and data.depthBias or 1,
						camDist = camDist,
						size = data.size,
						color = data.color,
						cone = data.cone
					}
				end
			end
		end
	
		if drawDataCount > DRAW_MAX then
			table.sort(drawData, function(a, b) return a.camDist < b.camDist end)
		end

		ECC.drawData = drawData

	end,
	false,
	"low-2"
)

addEventHandler("onClientPreRender", root,
	function()
		
		for i = 1, math.min(DRAW_MAX, #ECC.drawData) do

			local data = ECC.drawData[i]
			local x, y, z = data.pos[1], data.pos[2], data.pos[3]
			local sx, sy, sz = getScreenFromWorldPosition(x, y, z, DRAW_EDGE_TO_TOLERANCE, true)
			if sx or data.camDist < ECC.shaderSettings.fadeDistance[1]*0.15 then

				dxSetShaderValue(data.shader, "sCoronaTexture", data.texture)
				dxSetShaderValue(data.shader, "sCoronaPosition", data.pos)
				dxSetShaderValue(data.shader, "sCoronaDirection", data.dir)
				dxSetShaderValue(data.shader, "fDepthBias", data.depthBias)
				dxSetShaderValue(data.shader, "sLightPhi", data.cone[1])
				dxSetShaderValue(data.shader, "sLightTheta", data.cone[2])
				
				dxDrawMaterialLine3D(
					x, y, z - data.size*2,
					x, y, z + data.size*2,
					data.shader,
					data.size*4,
					tocolor(data.color[1], data.color[2], data.color[3], data.color[4]),
					x, y + 1, z
				)
			end
		end

	end,
	false,
	"low-3"
)