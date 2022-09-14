/* Ground shader with separate effects / textures per biome */
shader_type spatial;

varying vec2 groundTC;  // texture coordinates on ground
varying float elevation; // height in meters off ground
uniform sampler2D elevationTexture;
uniform float elevationScale=10.0; //< 0-1 color to actual Y meters
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
	NORMAL = (INV_CAMERA_MATRIX*vec4(normal,0.0)).xyz; // world to view coords
	
	// Detail map the ground
	vec2 tc = groundTC; // texture coordinates on model
	
	// Multi-octive noise
	vec2 tc1 = 8.0*tc;
	vec3 rockCoarse = texture(rockTexture,tc1).rgb;
	vec3 treeCoarse = texture(treeTexture,tc1).rgb;
	
	vec2 tc2 = 128.0*tc;
	vec3 rockDetail = texture(rockTexture,tc2).rgb;
	vec3 treeDetail = texture(treeTexture,tc2).rgb;
	
	vec3 rock = (rockCoarse+0.5)*(rockDetail+0.1); // grey rocks
	vec3 tree = (treeCoarse+0.4)*treeDetail; // contrasty trees
	vec3 water = vec3(0.1,0.2,0.4); // dim blue water
	vec3 snow = vec3(1,1,1); // snow
	
	// red: rock (bare gravel), green: trees (vegetation), blue: 
	vec3 biome = texture(biomeTexture,groundTC).rgb;
	
	ALBEDO = 0.5*vec3(1,1,1); // flat shaded
	ALBEDO = rock;  // rock debug
	ALBEDO = biome.r*rock + biome.g*biome*tree + biome.b*water;
	
	float snowline = 5.0;
	if (elevation>snowline) ALBEDO=mix(ALBEDO,snow,clamp(elevation-snowline,0,1));
	
}
