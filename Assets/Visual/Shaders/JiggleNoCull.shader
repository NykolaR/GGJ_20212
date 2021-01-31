shader_type spatial;
render_mode world_vertex_coords, cull_disabled;
// set vertex to global coords

// vertex shader vars
uniform float max_distance = 4.0f;
uniform float intensity = 0.0f;
uniform float time_scale = 1.0f;
uniform sampler2D noise;
uniform sampler2D distance_curve;
uniform vec3 possess_position = vec3(0.0f);

// fragment shader vars
uniform sampler2D albedo;
uniform float distance_fade_min = 0.0f;
uniform float distance_fade_max = 1.0f;

void vertex() {
	vec3 world_vec = VERTEX;//(WORLD_MATRIX * vec4(VERTEX, 0.0f)).rgb;
	vec3 noise_val = texture(noise, vec3((TIME * time_scale) + world_vec).xy).rgb;
	noise_val -= vec3(0.5f);
	noise_val *= (0.1f * intensity); // noise from like -0.1 to 0.1, vec3
	float dist = clamp(distance(possess_position, world_vec), 0, max_distance) / max_distance;
	//dist = 1.0f - dist;
	dist = texture(distance_curve, vec2(dist, 0.0)).r;
	
	VERTEX += (noise_val * dist);
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	/*{
		float fade_distance=-VERTEX.z;
		float fade=clamp(smoothstep(distance_fade_min,distance_fade_max,fade_distance),0.0,1.0);
		int x = int(FRAGCOORD.x) % 4;
		int y = int(FRAGCOORD.y) % 4;
		int index = x + y * 4;
		float limit = 0.0;
		
		if (x < 8) {
			if (index == 0) limit = 0.0625;
			if (index == 1) limit = 0.5625;
			if (index == 2) limit = 0.1875;
			if (index == 3) limit = 0.6875;
			if (index == 4) limit = 0.8125;
			if (index == 5) limit = 0.3125;
			if (index == 6) limit = 0.9375;
			if (index == 7) limit = 0.4375;
			if (index == 8) limit = 0.25;
			if (index == 9) limit = 0.75;
			if (index == 10) limit = 0.125;
			if (index == 11) limit = 0.625;
			if (index == 12) limit = 1.0;
			if (index == 13) limit = 0.5;
			if (index == 14) limit = 0.875;
			if (index == 15) limit = 0.375;
	}
	
	if (fade < limit)
		discard;
	}*/
}