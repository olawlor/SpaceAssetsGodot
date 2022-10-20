/*
  Draw an Iterated Function System (IFS) by reading texture pixels. 
  This draws a Sierpinski triangle, by sampling three copies.  

  Orion Lawlor, lawlor@alaska.edu, 2022-10-19 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport; // our viewport texture

// Read the viewport at this UV tex coordinate,
//   leaving center unchanged, and with this scaling.
vec3 readIFS(vec2 uv,vec2 center,float scale)
{
	uv -= center;
	uv *= scale;
	uv += center;
	//uv.x = uv.x*uv.x; //<- nonlinear!
	if (uv.x<0.0 || uv.x>1.0 || uv.y<0.0 || uv.y>1.0)
		return vec3(0.0); // out of bounds, return black
	return texture(viewport,uv).rgb;
}

void fragment()
{
	vec2 uv=UV; // texture coordinates
	vec3 color=vec3(0.0); // resulting color
		
	color += vec3(1.0,1.0,0.9)*readIFS(uv,vec2(0.0,1.0),2.0); // bottom left
	color += vec3(1.0,0.9,1.0)*readIFS(uv,vec2(1.0,1.0),2.0); // bottom right
	color += vec3(0.9,1.0,1.0)*readIFS(uv,vec2(0.5,0.0),2.0); // top
	
	color = color * 0.98 + 0.01; // exposure adjustment
	// color *= 1.0/3.0; // average these colors
	ALBEDO=color;
}
