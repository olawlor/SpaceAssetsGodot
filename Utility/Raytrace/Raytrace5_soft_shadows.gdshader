/*
  Raytracing demo 5: soft shadows from sphere
*/
shader_type spatial;
render_mode cull_disabled; //<- keep both sides of proxy geometry
render_mode unshaded; //<- turn off Godot lighting

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
	float alpha; // rays pass through here
	float shadow; // light passes through here
};

uniform sampler2D ringsTexture;

const float min_t=0.0001; //<- t that counts as an intersection

/*
 Intersect a ray with this sphere.

  Returns -1 if no intersection
 	sphere.xyz is origin
	sphere.w is radius
*/
bool ray_sphere_intersection(const vec4 sphere,vec3 Cworld,vec3 D,float max_t,inout Hit hit)
{
	vec3 C=Cworld - sphere.xyz; // ray start in "sphere space"
	float r=sphere.w; // radius of sphere
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
	float disc = b*b - 4.0*a*c;
	float t;
	float hitFrac=1.0;
	if (disc<0.0) { // miss (or near miss?)
		float min_disc=-0.1;
		if (disc<min_disc)
			return false; // true miss
		hitFrac = 1.0-disc/min_disc;
		t = -b/(2.0*a); // axis of symmetry
		if (t<min_t || t>max_t) return false;
	}
	else { // solid hit
		t = (-b - sqrt(disc))/(2.0*a); // closer
		if (t<min_t || t>max_t) { // intersection behind camera
			t = (-b + sqrt(disc))/(2.0*a); // farther
			if (t<min_t || t>max_t) return false;
		}
	}
	
	hit.t=t;
	hit.position = Cworld+t*D;
	hit.normal = normalize(hit.position-sphere.xyz);
	hit.uv=vec2(0.01,1.0-abs(hit.position.y-sphere.y)); // vertical axis colors
	hit.alpha=hitFrac;
	hit.shadow+=hitFrac;
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
	float minRadius=1.1; 
	float maxRadius=2.32; // radius of F ring relative to Saturn
	if (radius>maxRadius) return false; 
	if (radius<minRadius) return false; 
	
	hit.position = world;
	hit.t=tPlane;
	hit.normal=N;
	hit.uv=vec2(radius/maxRadius,0.99);
	float ringAlpha = clamp(texture(ringsTexture,hit.uv).r*1.2,0.0,1.0);
	hit.alpha = ringAlpha;
	hit.shadow +=ringAlpha;
	return true;
}

/*
  Intersect this ray with all geometry.
    max_t is how far to look at most.
	firstZ keeps only the closest hit (false for shadow rays).
	hit describes the intersection parameters.
*/
bool ray_world_intersection(vec3 C,vec3 D, float max_t, bool firstZ, inout Hit hit)
{
	float orig_max=max_t;
	hit.alpha=0.0;
	hit.shadow=0.0;
	vec4 saturnParam = vec4(0,0,0,1.0);
	float phase=TIME*0.4;
	vec3 moonOrbit = 1.7*vec3(sin(phase),0.3*sin(phase),cos(phase));
	vec4 moonParam = vec4(moonOrbit,0.3);
	float phase2=TIME*0.4+3.14;
	vec3 moon2Orbit = 1.7*vec3(sin(phase2),0.3*sin(phase2),cos(phase2));
	vec4 moon2Param = vec4(moon2Orbit,0.3);
	if (ray_plane_intersection(C,D,max_t,hit)) if (firstZ) max_t=hit.t; 
	if (ray_sphere_intersection(saturnParam,C,D,max_t,hit)) if (firstZ) max_t=hit.t; 
	if (ray_sphere_intersection(moonParam,C,D,max_t,hit)) if (firstZ) max_t=hit.t; 
	if (ray_sphere_intersection(moon2Param,C,D,max_t,hit)) if (firstZ) max_t=hit.t; 
	return max_t<orig_max;
}

// Compute lighting and total color of the world at this hit point
vec4 shade_hit(vec3 C,vec3 D,const Hit hit)
{
	vec3 worldHit = hit.position;
	vec3 worldNormal = normalize(hit.normal); 
	
	// back side lighting?  Messes up both rings and planet atmospheres
	//if (dot(D,worldNormal)>0.0) worldNormal = -worldNormal;
	
	// Look up albedo texture
	vec4 ring = texture(ringsTexture,hit.uv);
	vec3 albedo = ring.rgb;
	
	vec3 toLight=normalize(vec3(0,0.3,1.0));
	Hit shadowHit;
	float light=0.2; // ambient
	ray_world_intersection(hit.position+0.0001*hit.normal,toLight,1.0e9,false,shadowHit);
	{
		light += (1.0-clamp(shadowHit.shadow,0,1))*1.3*clamp(dot(worldNormal,toLight),0.0,1.0);
		
		if (false)
		{
			// Specular highlight
			vec3 toCamera = normalize(-D);
			vec3 halfway = normalize(0.5*toCamera+0.5*toLight);
			if (dot(halfway,worldNormal)>0.98) light=10.0;
		}
	}
	return vec4(light*albedo,hit.alpha);
}

// Compute the shaded color along this ray
bool color_along_ray(vec3 C,vec3 D,inout Hit hit,out vec4 color)
{
	float max_t = 1.0e9;
	if(!ray_world_intersection(C,D,max_t,true,hit)) return false;
	
	color = shade_hit(C,D,hit);
	return true;
}

void fragment()
{

	vec3 world=(CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=CAMERA_MATRIX[3].xyz;
	vec3 C = camera, D = normalize(world-camera); // L = C + t *D
	
	Hit hit;
	vec4 worldColor;
	if (!color_along_ray(C,D,hit,worldColor)) discard;
	
	if (worldColor.a<0.99)
	{ // transparent object: keep looking!
		vec4 nextColor;
		if (color_along_ray(hit.position,D,hit,nextColor))
		{
			worldColor.rgb = mix(nextColor.rgb,worldColor.rgb,worldColor.a);
			worldColor.a += nextColor.a;
		}
	}
	
	ALBEDO = worldColor.rgb;
	ALPHA = worldColor.a;
}
