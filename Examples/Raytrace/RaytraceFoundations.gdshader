/*
  Foundations of raytracing
*/
shader_type spatial;
render_mode cull_disabled; 
//render_mode cull_disabled; //<- keep both sides of proxy geometry
//render_mode unshaded; //<- turn off Godot lighting

void vertex() 
{
	
}
void fragment()
{
	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=INV_VIEW_MATRIX[3].xyz;
	
	//if (fract(world.x*0.99)<0.5) discard;
	
	ALBEDO = vec3(0.8);
	ALPHA = 0.9; // opacity
}
