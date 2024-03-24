shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport : source_color;


void fragment() 
{
	vec2 uv=UV + 0.0*TIME;
	vec2 scaleCenter = vec2(0.5,0.5);
	uv -= scaleCenter;
	uv *= 0.99;
	float rot = 0.005;
	uv.xy += rot*vec2(uv.y,-uv.x);
	uv += scaleCenter;
	vec3 oldColor = texture(viewport,uv).rgb;
	oldColor = oldColor * 0.995 - 0.51/256.0; 
	oldColor = fract(oldColor);
	ALBEDO=oldColor;
	// if (length(fract(uv*6.0))<0.1f) ALBEDO=vec3(1,0,0); // polkadot grid
}