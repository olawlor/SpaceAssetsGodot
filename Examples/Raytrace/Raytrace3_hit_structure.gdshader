/*
  Raytracing demo 3: "hit" data structure
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
render_mode unshaded; //<- turn off Godot lighting

void vertex() 
{
	
}

// Ray through world
struct Ray {
	vec3 origin;
	vec3 dir;
};

// Describes a ray-object intersection
struct Hit {
    vec3 position; // world coordinates position of ray-object hit point
    float t; // used for max_t
    vec3 normal; // world coordinates normal
    int material; //<- index into materials table
    vec2 uv; // texture coordinates
	float alpha;
};

uniform sampler2D ringsTexture;

const float min_t=0.0; //<- t that counts as an intersection

/*
  Returns -1 if no intersection
*/
bool ray_sphere_intersection(vec3 C,vec3 D,float max_t,inout Hit hit)
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
	if (det<0.0) return false;
	float t = (-b - sqrt(det))/(2.0*a); // closer
	if (t<min_t || t>max_t) { // intersection behind camera
		t = (-b + sqrt(det))/(2.0*a); // farther
		if (t<min_t || t>max_t) return false;
	}
	
	hit.t=t;
	hit.position = C+t*D;
	hit.normal = normalize(hit.position);
	hit.uv=vec2(0.01,1.0-abs(hit.position.y)); // vertical axis colors
	hit.alpha=1.0;
	return true;
}

bool ray_plane_intersection(vec3 C,vec3 D, float max_t, inout Hit hit)
{
	vec3 N = vec3(0,1,0); // sin(TIME*0.5),1,0);
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
	if (dn==0.0) return false;
	float tPlane = -cn / dn;
	if (tPlane < min_t || tPlane > max_t) return false;
	
	vec3 world = C + tPlane*D;
	float radius = length(world);
	float maxRadius=2.32; // radius of F ring relative to Saturn
	if (radius>maxRadius) return false; 
	
	hit.position = world;
	hit.t=tPlane;
	hit.normal=N;
	hit.uv=vec2(radius/maxRadius,0.99);
	hit.alpha = clamp(texture(ringsTexture,hit.uv).r*1.2,0.0,1.0);
	return true;
}

bool ray_world_intersection(vec3 C,vec3 D, float max_t, inout Hit hit)
{
	bool did=false;
	if (ray_sphere_intersection(C,D,max_t,hit)) { did=true; max_t=hit.t; }
	if (ray_plane_intersection(C,D,max_t,hit)) { did=true; max_t=hit.t; }
	return did;
}

void fragment()
{

	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=INV_VIEW_MATRIX[3].xyz;
	vec3 C = camera, D = world-camera; // L = C + t *D
	
	Hit hit;
	float max_t = 1.0e9;
	if(!ray_world_intersection(C,D,max_t,hit)) discard;
	
	vec3 worldHit = hit.position;
	vec3 worldNormal = normalize(hit.normal); 
	
	// back side lighting?
	if (dot(D,worldNormal)>0.0) worldNormal = -worldNormal;
	
	// Look up albedo texture
	vec4 ring = texture(ringsTexture,hit.uv);
	vec3 albedo = ring.rgb;
	
	vec3 toLight=normalize(vec3(0,0.4,1.0));
	Hit shadowHit;
	float light=0.2; // ambient
	if (!ray_world_intersection(hit.position+0.0001*hit.normal,toLight,1.0e9,shadowHit))
	{
		light += 1.3*clamp(dot(worldNormal,toLight),0.0,1.0);
		
		if (false)
		{
			// Specular highlight
			vec3 toCamera = normalize(-D);
			vec3 halfway = normalize(0.5*toCamera+0.5*toLight);
			if (dot(halfway,worldNormal)>0.98) light=10.0;
		}
	}
	
	NORMAL = (VIEW_MATRIX*vec4(worldNormal,0.0)).xyz;
	ALBEDO = vec3(albedo * light);
	ALPHA = hit.alpha;
}
