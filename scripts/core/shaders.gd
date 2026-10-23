class_name Shaders
extends RefCounted
## Shared canvas_item ShaderMaterials built in GDScript (GL Compatibility safe).
##
## The wind shader bends vertices from the sprite base upward with a phase
## derived from the sprite's world position (MODEL_MATRIX origin), so a whole
## meadow sways out of lockstep without any per-instance uniforms — those are
## unverified on the Compatibility renderer. Up to four "benders" (walking
## characters) are pushed through four vec4 shader globals; nearby grass bends
## away from them.


const GLOBAL_WIND_DIR := "tide_wind_dir"
const GLOBAL_WIND_STRENGTH := "tide_wind_strength"
const GLOBAL_WIND_SPEED := "tide_wind_speed"
const GLOBAL_BENDERS := ["tide_bender_0", "tide_bender_1", "tide_bender_2", "tide_bender_3"]

static var _wind: ShaderMaterial
static var _wind_registered := false
static var _water: ShaderMaterial


static func headless() -> bool:
	return DisplayServer.get_name() == "headless"


static func ensure_globals() -> void:
	if _wind_registered or headless():
		return
	RenderingServer.global_shader_parameter_add(GLOBAL_WIND_DIR, RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.12))
	RenderingServer.global_shader_parameter_add(GLOBAL_WIND_STRENGTH, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0)
	RenderingServer.global_shader_parameter_add(GLOBAL_WIND_SPEED, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.4)
	for name in GLOBAL_BENDERS:
		RenderingServer.global_shader_parameter_add(name, RenderingServer.GLOBAL_VAR_TYPE_VEC4, Vector4(0.0, 0.0, 0.0, 0.0))
	_wind_registered = true


static func wind_material() -> ShaderMaterial:
	if _wind == null:
		ensure_globals()
		var shader := Shader.new()
		shader.code = WIND_CODE
		_wind = ShaderMaterial.new()
		_wind.shader = shader
	return _wind


static func water_material() -> ShaderMaterial:
	if _water == null:
		var shader := Shader.new()
		shader.code = WATER_CODE
		_water = ShaderMaterial.new()
		_water.shader = shader
	return _water


static func set_wind(dir: Vector2, strength: float, speed: float = 1.4) -> void:
	if headless():
		return
	ensure_globals()
	RenderingServer.global_shader_parameter_set(GLOBAL_WIND_DIR, dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT)
	RenderingServer.global_shader_parameter_set(GLOBAL_WIND_STRENGTH, clampf(strength, 0.0, 2.5))
	RenderingServer.global_shader_parameter_set(GLOBAL_WIND_SPEED, speed)


static func push_benders(positions: Array) -> void:
	# xy = world position, z = bend radius in world units (<= 0 disables).
	if headless():
		return
	ensure_globals()
	for i in 4:
		var value := Vector4(0.0, 0.0, 0.0, 0.0)
		if i < positions.size():
			var b: Vector2 = positions[i]
			value = Vector4(b.x, b.y, 1.15, 0.0)
		RenderingServer.global_shader_parameter_set(GLOBAL_BENDERS[i], value)


static func clear_benders() -> void:
	push_benders([])


# A gentle default breeze so the meadow reads as alive the moment a world loads.
static func apply_default_breeze() -> void:
	set_wind(Vector2(1.0, 0.12), 0.9, 1.35)


const WIND_CODE := "
shader_type canvas_item;
global uniform vec2 tide_wind_dir = vec2(1.0, 0.1);
global uniform float tide_wind_strength = 1.0;
global uniform float tide_wind_speed = 1.4;
global uniform vec4 tide_bender_0 = vec4(0.0);
global uniform vec4 tide_bender_1 = vec4(0.0);
global uniform vec4 tide_bender_2 = vec4(0.0);
global uniform vec4 tide_bender_3 = vec4(0.0);

void vertex() {
	// Sprites get their phase from world position; batched grass carries a
	// per-instance seed in INSTANCE_CUSTOM.x (use_custom_data).
	float phase = MODEL_MATRIX[3].x * 0.37 + MODEL_MATRIX[3].y * 0.53 + INSTANCE_CUSTOM.x * 7.13;
	float t = TIME * tide_wind_speed;
	float sway = sin(t + phase) * 0.62 + sin(t * 2.31 + phase * 1.7) * 0.24;
	// Weight grows toward the TIP of the sprite. Canvas textures have UV.y = 0
	// at the top and this project anchors foliage art at its base, so the bend
	// is strongest at UV.y = 0.
	float w = pow(1.0 - clamp(UV.y, 0.0, 1.0), 1.3);
	vec2 origin = MODEL_MATRIX[3].xy;
	vec2 push = vec2(0.0);
	vec4 b0 = tide_bender_0;
	vec4 b1 = tide_bender_1;
	vec4 b2 = tide_bender_2;
	vec4 b3 = tide_bender_3;
	float d0 = distance(origin, b0.xy);
	float d1 = distance(origin, b1.xy);
	float d2 = distance(origin, b2.xy);
	float d3 = distance(origin, b3.xy);
	if (b0.z > 0.0 && d0 < b0.z) {
		push += normalize(origin - b0.xy + vec2(0.0001, 0.0)) * (1.0 - d0 / b0.z) * w * 2.6;
	}
	if (b1.z > 0.0 && d1 < b1.z) {
		push += normalize(origin - b1.xy + vec2(0.0001, 0.0)) * (1.0 - d1 / b1.z) * w * 2.6;
	}
	if (b2.z > 0.0 && d2 < b2.z) {
		push += normalize(origin - b2.xy + vec2(0.0001, 0.0)) * (1.0 - d2 / b2.z) * w * 2.6;
	}
	if (b3.z > 0.0 && d3 < b3.z) {
		push += normalize(origin - b3.xy + vec2(0.0001, 0.0)) * (1.0 - d3 / b3.z) * w * 2.6;
	}
	// Displacement is in LOCAL ART PIXELS on purpose: one shared material then
	// gives small tufts a lively bend and big canopies a subtle one, and it
	// works identically for Sprite2D and MultiMeshInstance2D batches.
	VERTEX += tide_wind_dir * sway * tide_wind_strength * w * 2.2 + push;
}
"


const WATER_CODE := "
shader_type canvas_item;
uniform vec4 shallow : source_color = vec4(0.43, 0.66, 0.65, 0.85);
uniform vec4 deep : source_color = vec4(0.24, 0.48, 0.53, 0.92);
uniform vec4 foam : source_color = vec4(0.86, 0.91, 0.87, 0.9);
uniform float band_scale = 42.0;
uniform float speed = 0.55;

void fragment() {
	// The texture is a shape mask: sea where alpha > 0, foam lip at the shore.
	float mask_a = texture(TEXTURE, UV).a;
	float wave = sin(UV.x * band_scale + TIME * speed) * 0.5
		+ sin(UV.x * band_scale * 0.53 - TIME * speed * 0.8) * 0.5;
	float band = fract(UV.y * 7.0 + wave * 0.18 + TIME * 0.06);
	float crest = smoothstep(0.86, 1.0, band);
	float depth = smoothstep(0.0, 1.0, UV.y);
	vec4 col = mix(shallow, deep, depth);
	vec3 rgb = mix(col.rgb, foam.rgb, crest * 0.85);
	COLOR = vec4(rgb, mix(col.a, 1.0, crest * 0.5) * mask_a);
}
"
