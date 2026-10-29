shader_type canvas_item;
uniform sampler2D materials : source_color, filter_linear_mipmap;
uniform vec2 world_size = vec2(64.0,40.0);
vec3 material_at(vec2 point,vec2 cell) {
	// Mirrored boundaries keep photographed materials continuous at every tile.
	vec2 mirrored=abs(fract(point*0.5)*2.0-1.0);
	return texture(materials,mirrored*0.485+0.0075+cell*0.5).rgb;
}
void fragment() {
	vec4 map=texture(TEXTURE,UV);
	vec2 world=UV*world_size;
	vec3 base=map.rgb;
	// Sea is blue/cyan. Cool forest greens still have G greater than B.
	float water=step(base.r*1.35,base.b)*step(base.g*0.95,base.b);
	float green=smoothstep(0.025,0.16,base.g-base.r)*(1.0-water);
	float sand=step(0.86,base.r)*step(base.b*1.18,base.g)*(1.0-green)*(1.0-water);
	vec2 cell=vec2(0,1);
	if (water>0.5) cell=vec2(1,1);
	else if (sand>0.5) cell=vec2(1,0);
	vec3 detail=material_at(world/(water>0.5 ? 8.0 : 5.0),cell);
	if (water<0.5) {
		vec3 grass=material_at(world/3.8,vec2(0,0));
		float gl=dot(grass,vec3(0.3,0.59,0.11));
		grass=mix(vec3(0.28,0.32,0.18),grass,0.56);
		grass*=0.88+gl*0.24;
		detail=mix(detail,grass,green);
	}
	float luma=dot(detail,vec3(0.3,0.59,0.11));
	detail=mix(vec3(luma),detail,water>0.5 ? 0.70 : 0.58);
	float shade=clamp(dot(base,vec3(0.3,0.59,0.11))*0.70+0.36,0.4,1.0);
	vec3 color=mix(base,detail*shade,0.95);
	COLOR=vec4(color,map.a);
}
