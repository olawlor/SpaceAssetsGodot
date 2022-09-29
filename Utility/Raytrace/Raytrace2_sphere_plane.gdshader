/*
  Raytracing demo 2: sphere and plane
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
render_mode unshaded; //<- turn off Godot lighting

void vertex() 
{
	
}

/*
  Returns -1 if no intersection
*/
float ray_sphere_intersection(vec3 C,vec3 D)
{
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
	if (det<0.0) return -1.0;
	float t = (-b - sqrt(det))/(2.0*a);
	if (t<0.0) { // intersection behind camera
		t = (-b + sqrt(det))/(2.0*a);
	}
	return t;
}

float ray_plane_intersection(vec3 C,vec3 D)
{
	vec3 N = vec3(sin(TIME*0.5),1,0);
	/*
		On line: L = C + t * D
		On plane: dot(P,N) = 0
		P = L
		dot(C + t * D,N) = 0
		dot(C,N) + t*dot(D,N) = 0
		t*dot(D,N) = -dot(C,N)
		t = -dot(C,N) / dot(D,N);
	*/
	float cn = dot(C,N);
	float dn = dot(D,N);
	if (dn==0.0) return -1.0;
	float tPlane = -cn / dn;
	
	vec3 world = C + tPlane*D;
	if (length(world)>1.2) return -1.0; 
	return tPlane;
}

void fragment()
{

	vec3 world=(CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=CAMERA_MATRIX[3].xyz;
	vec3 C = camera, D = world-camera; // L = C + t *D
	
	float tSphere = ray_sphere_intersection(C,D);
	float tPlane = ray_plane_intersection(C,D);
	
	float t=1.0e9;
	if (tSphere>0.0) t=tSphere;
	if (tPlane>0.0 && tPlane<t) t=tPlane;
	if (t>0.9e9) discard;
	
	vec3 worldHit = C + t * D;
	vec3 worldNormal = normalize(worldHit); 
	
	vec3 toLight=normalize(vec3(0,1,0.5));
	float light = dot(worldNormal,toLight);
	if (light<0.0) light=0.0;
	light+=0.1; // "ambient"
	
	vec3 toCamera = normalize(-D);
	vec3 halfway = normalize(0.5*toCamera+0.5*toLight);
	if (dot(halfway,worldNormal)>0.98) light=10.0;
	
	NORMAL = (INV_CAMERA_MATRIX*vec4(worldNormal,0.0)).xyz;
	ALBEDO = vec3(light);
}
