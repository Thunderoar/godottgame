shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(0.7,0.4,1.0,1.0);
uniform int element = 0;
uniform float clock = 0.0;
uniform float activation = 0.0;
uniform float fade = 1.0;
uniform bool projectile = false;
uniform bool beam = false;
uniform bool ring = false;
uniform float inner_radius = 0.6;
uniform bool motion = true;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 p=UV*2.0-1.0;
	float t=motion ? clock : 0.0;
	float r=beam ? abs(p.y) : length(p);
	float a=atan(p.y,p.x);
	float edge=1.0-smoothstep(0.975,1.0,r);
	float n=noise(p*5.0+vec2(t*0.6,-t*1.6));
	float n2=noise(p*11.0-vec2(0,t*2.0));
	float rim=exp(-abs(r-0.965)*48.0);
	float energy=0.0;
	vec3 color=tint.rgb;
	if (activation < 0.5 && !projectile) {
		float marks=step(0.72,sin(a*12.0));
		energy=rim*(0.75+0.2*sin(t*7.0))+edge*0.055+marks*exp(-abs(r-0.69)*60.0)*0.45;
		color=vec3(1.0,0.72,0.3);
	} else {
		float core=exp(-r*r*(projectile ? 4.0 : 2.7));
		if (element==4 || element==0) {
			float flames=pow(max(0.0,1.0-r+n*0.48-0.3),1.5);
			energy=flames*(0.45+n2*0.9)+rim*0.25;
			color=mix(tint.rgb,vec3(1.0,0.94,0.66),smoothstep(0.42,0.9,flames+n2*0.3));
		} else if (element==5) {
			float bolts=exp(-abs(p.x-sin(p.y*16.0+t*18.0)*0.15-sin(p.y*37.0-t*12.0)*0.08)*70.0);
			float branches=exp(-abs(p.x*0.7+p.y*0.4-sin(p.y*23.0+t*11.0)*0.08)*85.0);
			energy=(bolts+branches*0.65)*edge+core*0.22+rim*0.35;
			color=mix(tint.rgb,vec3(0.95,0.99,1.0),min(1.0,bolts));
		} else if (element==2) {
			float crystal=pow(max(0.0,cos(a*6.0+r*5.0)),12.0)*edge;
			energy=crystal*0.85+core*0.17+rim*0.55+n2*edge*0.14;
			color=mix(tint.rgb,vec3(0.95,1.0,1.0),crystal);
		} else if (element==1 || element==7 || element==9) {
			float spiral=pow(max(0.0,sin(a*3.0-r*16.0+t*5.0+n*2.0)),5.0);
			energy=spiral*edge*(0.25+r*0.5)+rim*0.5+core*0.15;
			if (element==9) energy*=smoothstep(0.12,0.42,r);
		} else if (element==3 || element==6) {
			float cracks=pow(1.0-abs(sin(p.x*17.0+n*5.0)*sin(p.y*16.0+n*4.0)),14.0);
			energy=cracks*edge*0.7+rim*0.45+core*0.12;
		} else {
			float bubbles=pow(max(0.0,noise(p*13.0+vec2(0,t))-0.4),2.0)*4.0;
			energy=edge*(0.25+n*0.3+bubbles)+rim*0.45;
		}
		if (ring) energy*=smoothstep(inner_radius-0.035,inner_radius+0.035,r);
		if (projectile) { energy+=core*0.7; color=mix(color,vec3(1.0),core*0.75); }
	}
	if (ring) energy*=smoothstep(inner_radius-0.035,inner_radius+0.035,r);
	float alpha=clamp(energy*fade,0.0,0.92)*edge;
	COLOR=vec4(color*(1.0+min(energy,1.0)*0.32),alpha);
}
