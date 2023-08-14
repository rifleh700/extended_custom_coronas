
camera = getCamera()

CORONA_TYPE_SIMPLE = "simple"
CORONA_TYPE_DIRECTIONAL = "directional"
CORONA_TYPE_NOMAT = "nomat"

QUAD1X1_VERTICES = {
	{0, 0, 0, tocolor(255, 255, 255, 255), 0, 0},
	{0, 1, 0, tocolor(255, 255, 255, 255), 0, 1},
	{1, 0, 0, tocolor(255, 255, 255, 255), 1, 0},
	{1, 1, 0, tocolor(255, 255, 255, 255), 1, 1}
}

DRAW_MAX = 255
DRAW_EDGE_TO_TOLERANCE = 0.35

FADE_DISTANCE_DEFAULT = {300, 250}
LIGHT_CONE_DEFAULT = {math.pi/4, math.pi/12}
LIGHT_ATTENUATION_POWER_DEFAULT = 2

TEXTURE_DEFAULT = dxCreateTexture("textures/coronastar.png", "dxt1", true, "clamp")

SHADERS = {
	[CORONA_TYPE_SIMPLE] = dxCreateShader("shaders/primitive3D_corona.fx", 0, 0, false, "all"),
	[CORONA_TYPE_DIRECTIONAL] = dxCreateShader("shaders/primitive3D_corona_dir.fx", 0, 0, false, "all"),
	[CORONA_TYPE_NOMAT] = dxCreateShader("shaders/primitive3D_corona_nomat.fx", 0, 0, false, "all")
}
for _, shader in pairs(SHADERS) do
	dxSetShaderValue(shader, "sLightFalloff", 1)
	dxSetShaderValue(shader, "sCoronaRescale", 1)
	dxSetShaderValue(shader, "sCoronaScaleSpread", 0.85)
	dxSetShaderValue(shader, "sFlipTexture", false)
	dxSetShaderValue(shader, "uvMul", 1, 1)
	dxSetShaderValue(shader, "uvPos", 0, 0)
	dxSetShaderValue(shader, "fCullMode", 1)
end

ECC = {}

ECC.coronasData = {}
ECC.coronasDataList = {}
ECC.updateCoronasDataList = false
ECC.drawData = {}

function ECC.getCallingResource()

	if not sourceResource then return nil end
	if type(sourceResource) ~= "userdata" then return nil end
	if getUserdataType(sourceResource) ~= "resource-data" then return nil end

	return sourceResource
end

function ECC.create(ctype, texture, x, y, z, dirX, dirY, dirZ, size, r, g, b, a)

	local data = {
		ctype = ctype,
		texture = texture,
		pos = {x, y, z},
		int = 0,
		dim = 0,
		dir = {dirX, dirY, dirZ},
		size = size,
		color = {r, g, b, a},
		lightCone = {LIGHT_CONE_DEFAULT[1], LIGHT_CONE_DEFAULT[2]},
		attenuationPower = LIGHT_ATTENUATION_POWER_DEFAULT,
		fadeDist = {FADE_DISTANCE_DEFAULT[1], FADE_DISTANCE_DEFAULT[2]},
		depthBias = size,
		parent = ECC.getCallingResource()
	}

	local element = createElement("corona")
	addEventHandler("onClientElementDestroy", element, ECC.onDestroy, false)
	addEventHandler("onClientElementDestroy", texture, ECC.onTextureDestroy, false)

	ECC.coronasData[element] = data
	ECC.updateCoronasDataList = true

	return element
end

function ECC.onDestroy()

	ECC.coronasData[this] = nil
	ECC.updateCoronasDataList = true

end

function ECC.onTextureDestroy()

	for corona, data in pairs(ECC.coronasData) do
		if data.texture == this then
			data.texture = TEXTURE_DEFAULT
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

addEventHandler("onClientPreRender", root,
	function()
		if not ECC.updateCoronasDataList then return end

		ECC.updateCoronasDataList = false

		local coronasDataList = {}
		local coronasDataListCount = 0
		for corona, data in pairs(ECC.coronasData) do
			coronasDataListCount = coronasDataListCount + 1
			coronasDataList[coronasDataListCount] = data
		end
		ECC.coronasDataList = coronasDataList

	end,
	false,
	"low-1"
)

addEventHandler("onClientPreRender", root,
	function()

		local farClipDist = getFarClipDistance()
		local cx, cy, cz = getElementPosition(camera)
		local cint = getElementInterior(localPlayer)
		local cdim = getElementDimension(camera)

		local drawData = {}
		local drawDataCount = 0
		for i, data in ipairs(ECC.coronasDataList) do

			local attachedTo = data.attachedTo
			if attachedTo then

				data.int = getElementInterior(attachedTo)
				data.dim = getElementDimension(attachedTo)

				local em = getElementMatrix(attachedTo)
				data.pos = {getPositionFromMatrixOffset(em, data.offsets[1], data.offsets[2], data.offsets[3])}

				if data.ctype == CORONA_TYPE_DIRECTIONAL then
					local ex, ey, ez = getMatrixPosition(em)
					local dx, dy, dz = getPositionFromMatrixOffset(em, data.offsets[4], data.offsets[5], data.offsets[6])
					data.dir = {dx - ex, dy - ey, dz - ez}
				else
					data.dir = {0, 1, 0}
				end
			end

			if data.color[4] > 0 and data.int == cint and (data.dim == -1 or data.dim == cdim) then
				local camDist = getDistanceBetweenPoints3D(data.pos[1], data.pos[2], data.pos[3], cx, cy, cz)
				if camDist < math.min(data.fadeDist[1] + data.size, farClipDist) then

					drawDataCount = drawDataCount + 1
					drawData[drawDataCount] = {
						texture = data.texture,
						shader = SHADERS[data.ctype],
						pos = data.pos,
						dir = data.dir,
						size = data.size,
						color = {data.color[1]/255, data.color[2]/255, data.color[3]/255, data.color[4]/255},
						attenuationPower = data.attenuationPower,
						lightCone = data.lightCone,
						depthBias = data.depthBias,
						fadeDist = data.fadeDist,
						camDist = camDist
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
			local sx, _, _ = getScreenFromWorldPosition(data.pos[1], data.pos[2], data.pos[3], DRAW_EDGE_TO_TOLERANCE, true)
			if sx then

				dxSetShaderValue(data.shader, "sTexColor", data.texture)
				dxSetShaderValue(data.shader, "sElementPosition", data.pos)
				dxSetShaderValue(data.shader, "sElementDirection", data.dir)
				dxSetShaderValue(data.shader, "sElementSize", data.size)
				dxSetShaderValue(data.shader, "sElementColor", data.color)
				dxSetShaderValue(data.shader, "sLightPhi", data.lightCone[1])
				dxSetShaderValue(data.shader, "sLightTheta", data.lightCone[2])
				dxSetShaderValue(data.shader, "sLightAttenuationPower", data.attenuationPower)
				dxSetShaderValue(data.shader, "fDepthBias", data.depthBias)
				dxSetShaderValue(data.shader, "gDistFade", data.fadeDist)

				dxDrawMaterialPrimitive3D(
					"trianglestrip",
					data.shader,
					false,
					QUAD1X1_VERTICES[1], QUAD1X1_VERTICES[2], QUAD1X1_VERTICES[3], QUAD1X1_VERTICES[4])
			end
		end
	end,
	false,
	"low-3"
)