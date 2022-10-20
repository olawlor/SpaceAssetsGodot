/*
  Draw an Iterated Function System (IFS) by reading texture pixels. 
  This is a basic spiral reaction-diffusion equation.
  Orion Lawlor, lawlor@alaska.edu, 2022-10-19 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport; // our viewport texture

void fragment()
{
	vec2 uv=UV; // texture coordinates
	vec3 color=vec3(0.0); // resulting color
	
	uv -= 0.5; // center on 0,0
	uv = uv*0.995; // scale texture
	float angle=0.01; // radians of rotation
	uv = vec2(
		cos(angle)*uv.x + sin(angle)*uv.y,
		-sin(angle)*uv.x + cos(angle)*uv.y
	);
	uv += 0.5; // recenter again
	
	color = texture(viewport,uv).rgb; // read old texture
	color = fract(color-0.005); // slight darkening, with wraparound
	
	ALBEDO=color;
}
