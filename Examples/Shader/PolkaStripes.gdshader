// Stripes!
shader_type spatial;
//render_mode unshaded;

varying vec3 myStripe;
void vertex()
{
	myStripe = VERTEX;
}

uniform float polkaScale=4.0; 
uniform float stripeRepeats=5.0; // stripes per meter
uniform vec4 stripeColor : source_color;
uniform sampler2D stripeTexture;
void fragment()
{
	vec2 dotCoords = fract(myStripe.xz*polkaScale*0.999)-vec2(0.5,0.5);
	if (length(dotCoords)<0.2)
	{ // inside a polka dot!
		ALBEDO = vec3(1,0,0);
	}
	else { // stripe
		float where=fract(myStripe.x*stripeRepeats*0.999);
		vec3 stripe = stripeColor.xyz;
		vec3 back = texture(stripeTexture,UV).rgb;
		if (where<0.2)
			ALBEDO = back * 0.5 + stripe * 0.5;
		else
		{
			ALBEDO = back;
		}
	}
		
}

