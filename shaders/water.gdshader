shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D scene_color : hint_screen_texture, filter_linear;
uniform sampler2D scene_depth : hint_depth_texture, filter_linear;

uniform vec3 shallow_color : source_color = vec3(0.08, 0.42, 0.48);
uniform vec3 scattering_color : source_color = vec3(0.015, 0.19, 0.23);
uniform vec3 absorption_coefficients = vec3(1.35, 0.32, 0.12);
uniform vec3 foam_color : source_color = vec3(0.86, 0.94, 0.92);
uniform float refraction_strength : hint_range(0.0, 0.05) = 0.012;
uniform float wave_frequency : hint_range(0.1, 4.0) = 1.1;
uniform float wave_amplitude : hint_range(0.0, 0.4) = 0.12;
uniform float wave_speed : hint_range(0.0, 4.0) = 0.7;
uniform float wave_normal_strength : hint_range(0.0, 3.0) = 1.0;
uniform float foam_depth : hint_range(0.01, 1.0) = 0.18;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.65;

varying vec3 water_world_position;
varying vec3 water_world_normal;
varying vec4 water_depth_coefficients;

void vertex() {
	water_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	water_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	water_depth_coefficients = vec4(
		INV_PROJECTION_MATRIX[2][2],
		INV_PROJECTION_MATRIX[3][2],
		INV_PROJECTION_MATRIX[2][3],
		INV_PROJECTION_MATRIX[3][3]
	);
}

vec2 wave_gradient(vec2 position, vec2 direction, float frequency, float amplitude, float speed, float phase_offset) {
	vec2 direction_normalized = normalize(direction);
	float phase = dot(position, direction_normalized) * frequency - TIME * speed + phase_offset;
	return direction_normalized * (amplitude * frequency * cos(phase));
}

float linear_eye_depth(vec2 uv, float raw_depth) {
	float view_z = raw_depth * water_depth_coefficients.x + water_depth_coefficients.y;
	float view_w = raw_depth * water_depth_coefficients.z + water_depth_coefficients.w;
	return -view_z / max(abs(view_w), 0.00001);
}

void fragment() {
	vec3 base_world_normal = normalize(water_world_normal);
	vec2 position = water_world_position.xz;
	vec2 wave_slope = wave_gradient(position, vec2(1.0, 0.22), wave_frequency, wave_amplitude, wave_speed, 0.0);
	wave_slope += wave_gradient(position, vec2(-0.32, 1.0), wave_frequency * 1.73, wave_amplitude * 0.43, wave_speed * 1.31, 1.7);
	wave_slope += wave_gradient(position, vec2(0.72, 0.69), wave_frequency * 2.41, wave_amplitude * 0.2, wave_speed * 0.82, 4.1);

	float horizontal_surface = smoothstep(0.25, 0.8, abs(base_world_normal.y));
	vec3 perturbed_world_normal = normalize(base_world_normal + vec3(-wave_slope.x, 0.0, -wave_slope.y) * wave_normal_strength * horizontal_surface);
	NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_world_normal, 0.0)).xyz);

	float view_cosine = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = 0.0204 + (1.0 - 0.0204) * pow(1.0 - view_cosine, 5.0);
	vec2 refracted_uv = clamp(SCREEN_UV + NORMAL.xy * refraction_strength * (1.0 - fresnel), vec2(0.001), vec2(0.999));

	float raw_scene_depth = texture(scene_depth, refracted_uv).r;
	float scene_eye_depth = linear_eye_depth(refracted_uv, raw_scene_depth);
	float water_eye_depth = -VERTEX.z;
	float water_thickness = max(scene_eye_depth - water_eye_depth, 0.0);

	vec3 transmittance = exp(-absorption_coefficients * water_thickness);
	vec3 refracted_color = texture(scene_color, refracted_uv).rgb;
	vec3 transmitted_color = refracted_color * transmittance + scattering_color * (1.0 - transmittance);
	float absorption = 1.0 - exp(-water_thickness * 0.7);
	vec3 water_surface_color = mix(shallow_color, transmitted_color, 0.82);

	float foam_edge = 1.0 - smoothstep(0.015, foam_depth, water_thickness);
	float foam_pattern = 0.5 + 0.25 * sin(position.x * 7.3 + TIME * 0.8) + 0.25 * cos(position.y * 6.1 - TIME * 0.63);
	float foam = clamp(foam_edge * smoothstep(0.25, 0.8, foam_pattern) * foam_strength, 0.0, 1.0);

	ALBEDO = mix(water_surface_color, foam_color, foam);
	ALBEDO = mix(ALBEDO, shallow_color, fresnel * 0.25);
	ALPHA = clamp(0.16 + absorption * 0.58 + fresnel * 0.22 + foam * 0.24, 0.08, 0.94);
	METALLIC = 0.0;
	ROUGHNESS = 0.075;
	SPECULAR = 0.5;
}
