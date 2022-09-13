/* Ground shader with multi-octave shading */
shader_type spatial;

// Terrain from sin waves:
uniform vec3 waveRate=vec3(0.1,0.0,0.04);
uniform vec3 waveHeight=vec3(6.0,0.0,8.0);

void vertex() {
	vec3 wave = waveRate*VERTEX; // +TIME*0.1; // wave phase in radians
	
	// Adjust the vertex height:
	VERTEX.y += waveHeight.x*sin(wave.x) + waveHeight.z*sin(wave.z);
	
	// Tilt the surface normal, for lighting:
	//   = derivative of height change in each direction
	NORMAL.x += waveHeight.x*waveRate.x*cos(wave.x);
	NORMAL.z += waveHeight.z*waveRate.z*cos(wave.z);
}

uniform sampler2D groundTexture;
void fragment()
{
	vec2 tc = UV*100.0; // texture coordinates on model
	
	// Multi-octive noise
	vec2 tc1 = tc;
	vec3 coarse = texture(groundTexture,tc1).rgb;
	
	vec2 tc2 = 8.0*tc;
	vec3 detail = texture(groundTexture,tc2).rgb;
	
	// ALBEDO = coarse*0.5+detail*0.5; // average (looks muddy)
	ALBEDO = (coarse+0.5)*detail; // multiply (sharp detail)
}
