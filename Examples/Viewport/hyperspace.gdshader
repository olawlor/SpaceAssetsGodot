shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport;


void fragment() 
{
	vec2 uv=UV + 0.0*TIME;
	vec2 scaleCenter = vec2(0.5,0.5);
	uv -= scaleCenter;
	uv *= 0.95;
	uv += scaleCenter;
	vec3 oldColor = texture(viewport,uv).rgb;
	oldColor = oldColor * 0.99 - 0.51/256.0; 
	oldColor = fract(oldColor);
	ALBEDO=oldColor;
}