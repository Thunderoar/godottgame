shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.5,0.4,0.6,1.0);
uniform vec4 accent : source_color = vec4(0.8,0.5,1.0,1.0);
uniform int element = 0;
uniform bool motion = true;
void fragment() {
	vec4 stone=texture(TEXTURE,UV);
	vec2 p=UV*vec2(1.5,1.0);
	float time=motion ? TIME : 0.0;
	float seam=pow(max(0.0,1.0-abs(sin(p.x*42.0+sin(p.y*19.0)*2.0)*sin(p.y*38.0))),22.0);
	float pools=smoothstep(0.64,0.94,sin(p.x*17.0)*sin(p.y*23.0));
	float variation=0.93+0.07*sin(p.x*8.0+p.y*13.0);
	vec3 base=stone.rgb*mix(vec3(0.96),tint.rgb,0.36)*variation;
	float glow=seam*0.05;
	if (element==0 || element==3 || element==4) glow=seam*pools*(0.35+0.08*sin(time*1.2));
	if (element==2) base=mix(base,vec3(0.42,0.65,0.75),pools*0.25);
	if (element==7) glow=pools*(0.05+0.03*sin(p.x*24.0+p.y*13.0-time));
	if (element==6 || element==8) base=mix(base,tint.rgb*0.35,pools*0.35);
	float vignette=1.0-smoothstep(0.35,0.76,length(UV-0.5))*0.48;
	COLOR=vec4((base+accent.rgb*glow)*vignette,stone.a);
}
