shader_type spatial;

void fragment()
{
	ALBEDO = fract(VERTEX);
}
