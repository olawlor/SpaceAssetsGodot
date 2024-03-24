/*
 Draw a cartoon style skin tone, using vertex colors.
*/
shader_type spatial;
render_mode unshaded;

varying vec3 world_normal;
uniform vec3 light_dir=vec3(0.5,1,-0.5); // points to light source

void vertex() {
	world_normal=NORMAL;
}

void fragment() {
	vec3 vertex_color = pow(COLOR.rgb,vec3(0.5)); //<- fix up gamma on colors
	vec3 lighting = vec3(1.0);
	
	if (dot(world_normal,light_dir)<0.0) lighting=vec3(0.5); // in shadow
	
	ALBEDO=lighting * vertex_color;
}
