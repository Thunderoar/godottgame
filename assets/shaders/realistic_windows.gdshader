shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 art=texture(TEXTURE,UV);
	float amber=smoothstep(0.7,0.92,art.r)*smoothstep(0.45,0.7,art.g)*(1.0-smoothstep(0.4,0.65,art.b));
	COLOR=vec4(vec3(1.0,0.68,0.25),art.a*amber)*COLOR;
}
