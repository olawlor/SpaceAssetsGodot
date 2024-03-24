/* Ground shader with separate effects / textures per biome */
shader_type spatial;

varying vec2 groundTC;  // texture coordinates on ground
varying float elevation; // height in meters off ground
uniform sampler2D elevationTexture;
uniform float elevationScale=6.2; //< 0-1 color to actual Y meters (Denali==1.0)
void vertex() {
	groundTC = UV.xy;
	elevation = elevationScale*texture(elevationTexture,groundTC).r;
	
	// Adjust the vertex height:
	VERTEX.y += elevation;
}

uniform sampler2D rockTexture; // detail texture for rocks
uniform sampler2D treeTexture; // detail texture for forest
uniform sampler2D normalTexture;
uniform sampler2D biomeTexture;
void fragment()
{
	// Bump map the surface using the normal texture
	vec3 normal = texture(normalTexture,groundTC).rgb;
	normal = normal*2.0-1.0; // convert color 0..1 to coordinate -1..+1
	normal.xy *= 0.5; // tone down the slopes
	normal = vec3(normal.x,normal.z,-normal.y); //<- swizzle to swap Z-up to Y-up
	NORMAL = (VIEW_MATRIX*vec4(normal,0.0)).xyz; // world to view coords
	
	// red: rock (bare gravel), green: trees (vegetation), blue: 
	vec3 biome = texture(biomeTexture,groundTC).rgb;
	
	// Detail map the ground
	vec2 tc = groundTC; // texture coordinates on model
	
	// Rocks and trees from multi-octive noise: coarse and fine detail textures
	vec3 rockCoarse = texture(rockTexture,512.0*groundTC).rgb;
	vec3 treeCoarse = texture(treeTexture,64.0*groundTC).rgb;
	
	vec3 rockDetail = texture(rockTexture,2048.0*groundTC).rgb;
	vec3 treeDetail = texture(treeTexture,512.0*groundTC).rgb;
	
	vec3 rock = (rockCoarse+0.5)*(rockDetail+0.1); // grey rocks
	vec3 tree = (treeCoarse+0.4)*treeDetail; // contrasty trees
	tree *= biome; // tint trees to the color of the satellite image
	
	// Ocean with gentle waves
	vec3 oceanColor = vec3(0,0.1,0.3);
	float waveTop = pow(abs(sin(groundTC.x*1000.0+0.1*TIME+5.0*sin(groundTC.y*100.0))),32.0);
	oceanColor = mix(oceanColor,vec3(1,1,1),0.1*waveTop);
	float oceanFraction = pow(biome.b,4.0);
	
	// Snow-capped peaks
	vec3 snow = vec3(1,1,1); // snow color
	float snowFraction = 0.0;
	float snowline = 3.0; // altitude where snow starts (km)
	if (elevation>snowline) {
		snowFraction = clamp(0.5*(elevation-snowline),0,0.7);
	}
	
	// Mix together all these effects:
	ALBEDO = mix(
		mix(
			mix(rock,tree,biome.g),
			oceanColor,oceanFraction
		),
		snow,snowFraction
	);
	
	// ALBEDO = 0.5*vec3(1,1,1); // flat shaded	
}
