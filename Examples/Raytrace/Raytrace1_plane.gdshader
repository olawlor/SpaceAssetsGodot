/*
  Raytracing demo 0: find our world-coordinates position
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
//render_mode unshaded; //<- turn off Godot lighting

void vertex() 
{
	
}

void fragment()
{

	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=INV_VIEW_MATRIX[3].xyz;
	vec3 C = camera, D = world-camera; // L = C + t *D
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
	if (dn==0.0) discard;
	float t = -cn / dn;
	if (t<0.0) { // intersection behind camera
		discard;
	}
	
	vec3 worldHit = C + t * D;
	if (length(worldHit)>1.0) discard;
	vec3 worldNormal = N; 
	NORMAL = (VIEW_MATRIX*vec4(worldNormal,0.0)).xyz;
	ALBEDO = vec3(fract(worldHit*4.0));
	ALBEDO.g=0.0; //<- roundoff
}
