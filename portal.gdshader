shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D texture_albedo : source_color;


void fragment() {
	// Called for every pixel the material is visible on.
	vec2 base_uv = SCREEN_UV;
	//vec2 base_uv = UV;
	//base_uv.x = -base_uv.x;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo_tex.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
