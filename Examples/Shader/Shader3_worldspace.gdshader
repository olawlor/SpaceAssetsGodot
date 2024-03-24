shader_type spatial;
varying vec3 world;
void vertex() 
{
	world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment()
{
	ALBEDO = fract(world);
}
