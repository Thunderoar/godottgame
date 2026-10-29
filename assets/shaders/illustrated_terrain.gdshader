shader_type canvas_item;
// Preserve the authoritative map's geometry; use quiet illustrated materials.
uniform vec4 meadow : source_color = vec4(0.62,0.69,0.34,1.0);
uniform vec4 trail : source_color = vec4(0.65,0.53,0.39,1.0);
uniform vec4 beach : source_color = vec4(0.94,0.83,0.58,1.0);
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
	vec4 map=texture(TEXTURE,UV);
	vec3 base=map.rgb;
	float water=step(base.r*1.35,base.b)*step(base.g*0.95,base.b);
	float foam=step(0.8,base.r)*step(0.8,base.b)*step(0.85,base.g);
	water=max(water,foam);
	float grass=smoothstep(0.025,0.16,base.g-base.r)*(1.0-water);
	float sand=smoothstep(0.85,0.93,base.r)*step(base.b*1.18,base.g)*(1.0-grass)*(1.0-water);
	vec3 land=mix(trail.rgb,meadow.rgb,grass);
	land=mix(land,beach.rgb,sand);
	float shade=clamp(dot(base,vec3(0.3,0.59,0.11))*0.17+0.89,0.93,1.03);
	land*=shade;
	vec2 pixel=floor(UV*vec2(2048,1280));
	float fleck=step(0.997,hash(floor(pixel/3.0)));
	land+=vec3(0.045,0.035,0.02)*fleck*(1.0-grass);
	vec2 world=UV*vec2(64,40);
	float coast=mix(21.0,37.0,smoothstep(0.0,1.0,clamp(world.x/25.0,0.0,1.0)))+sin(world.x*32.0/31.0)*0.55;
	coast+=smoothstep(704.0,804.0,world.x*32.0)*7.0;
	float depth=max(0.0,world.y-coast);
	vec3 sea=mix(vec3(0.36,0.71,0.72),vec3(0.13,0.38,0.49),smoothstep(0.0,6.0,depth));
	sea=mix(sea,vec3(0.84,0.92,0.81),foam*0.8);
	COLOR=vec4(mix(land,sea,water),map.a);
}
