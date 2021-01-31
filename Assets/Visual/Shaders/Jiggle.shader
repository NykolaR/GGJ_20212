shader_type spatial;
render_mode world_vertex_coords;
// set vertex to global coords

uniform float max_distance = 4.0f;
uniform float intensity = 0.0f;
uniform float time_scale = 1.0f;
uniform sampler2D noise;
uniform sampler2D distance_curve;
uniform vec3 possess_position = vec3(0.0f);

void vertex() {
	vec3 bottom = (texture(noise, vec3((TIME * time_scale) + VERTEX).xy).rgb - vec3(0.5f)) * 0.1f * intensity;
	float top = texture(distance_curve, vec2((clamp(distance(possess_position, VERTEX), 0, max_distance) / max_distance), 0.0)).r;
	VERTEX = VERTEX + (bottom * top);
}
