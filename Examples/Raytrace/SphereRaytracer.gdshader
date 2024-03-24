/*
  Raytracing demo: find the intersection of a camera ray with a sphere.
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
render_mode unshaded; //<- turn off Godot lighting

varying vec3 world; // XYZ world-coordinates proxy geometry position
varying vec3 camera; // XYZ world-coordinates camera position

void vertex() 
{
	world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	camera = INV_VIEW_MATRIX[3].xyz;
}

void fragment()
{
	vec3 C = camera;
	vec3 D = normalize(world - camera); // points from camera to world

	// Quadratic equation: 0 = c + t*b + t*t*a
	float r=1.0; // radius of sphere
	float c = dot(C,C)-r*r;
	float b = 2.0*dot(C,D);
	float a = dot(D,D);
	
	float determinant = b*b - 4.0*a*c;
	if (determinant<0.0) discard; // ray missed sphere
	float t = (-b -sqrt(determinant))/(2.0*a);
	if (t<0.0) { // close ray hit is behind the camera
		t = (-b +sqrt(determinant))/(2.0*a); 
	}
	
	vec3 worldHit = C + t*D; // world coordinates hit point
	vec3 worldNormal = normalize(worldHit); // surface normal is easy for a sphere
	ALBEDO = vec3(0.9); // flat color
	ALBEDO = 0.8*fract(worldHit*4.0); // plaid colors
	
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX*vec4(worldHit,1.0);
	DEPTH = (clip.z/clip.w) * .5f + .5f;  // write our depth (needs GLES 3, sadly)
	NORMAL = (VIEW_MATRIX*vec4(worldNormal,0.0)).xyz; // Godot wants normal in camera coords
	
	// Lighting
	vec3 toLight=normalize(vec3(0,1,1)); // 45 degree angle
	float specular = 0.0;
	float lighting = dot(toLight, worldNormal);
	if (lighting<0.0) lighting=0.0; // facing away from camera
	else {
		// Facing the light, add specular
		vec3 toCamera = normalize(camera - worldHit);
		vec3 halfway = normalize(toCamera + toLight); // Blinn's "halfway vector"
		float phongExponent = 100.0; // Phong's (hacky) exponent for specular reflection
		specular = pow(dot(worldNormal,halfway),phongExponent);
	}
	lighting += 0.1; // approximate ambient lighting (sky/floor/etc)
	vec3 diffuse = ALBEDO * lighting; // diffuse lighting

	vec3 color = diffuse + specular;
	ALBEDO = color;
}
