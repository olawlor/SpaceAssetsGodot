/*
 Draw an outline around this shape, by scaling and front-face culling. 
 Requires smooth shaded vertex normals. 
*/
shader_type spatial;
render_mode unshaded;
render_mode cull_front;

uniform float outline_thick=0.001;
uniform vec4 outline_color  : source_color =vec4(0.0);
uniform float outline_black=0.8;

void vertex() {
	VERTEX += outline_thick*NORMAL; // slightly expand the mesh 
}
void fragment() {
	ALBEDO=outline_color.rgb; // color
	ALPHA=outline_black; // mostly opaque
}