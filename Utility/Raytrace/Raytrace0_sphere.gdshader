/*
  Raytracing demo 0: intersect ray with sphere
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
//render_mode unshaded; //<- turn off Godot lighting

void vertex() 
{
	
}

void fragment()
{

	vec3 world=(CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=CAMERA_MATRIX[3].xyz;
	vec3 C = camera, D = world-camera; // L = C + t *D
	float r=1.0; // radius of sphere
	/*
		On line: L = C + t * D
		On sphere: dot(P,P) = r*r
		L = P
		dot(C + t * D,C + t * D) = r*r
		dot(C,C + t * D) + dot(t*D,C + t * D) = r*r
		dot(C,C) + dot(C,t * D) + dot(t*D,C + t * D) = r*r
		dot(C,C) + t*dot(C,D) + t*dot(D,C + t * D) = r*r
		dot(C,C) + t*dot(C,D) + t*(dot(D,C) + t * dot(D,D)) = r*r
		dot(C,C)-r*r + 2.0*t*dot(C,D) + t * t * dot(D,D) = 0
		c + b*t + a*t^2 = 0
		t = (-b +- sqrt(b*b - 4.0*a*c))/2.0*a;
	*/
	float c = dot(C,C)-r*r;
	float b = 2.0*dot(C,D);
	float a = dot(D,D);
	float det = b*b - 4.0*a*c;
	if (det<0.0) discard;
	float t = (-b - sqrt(det))/(2.0*a);
	if (t<0.0) { // intersection behind camera
		t = (-b + sqrt(det))/(2.0*a);
		if (t<0.0)
			discard;
	}
	
	vec3 worldHit = C + t * D;
	vec3 worldNormal = normalize(worldHit); 
	NORMAL = (INV_CAMERA_MATRIX*vec4(worldNormal,0.0)).xyz;
	ALBEDO = vec3(fract(worldHit*4.0));
}
