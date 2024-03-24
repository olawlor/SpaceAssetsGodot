/*
Distance field based ray-object renderer.

Dr. Orion Lawlor, lawlor@alaska.edu, 2022-10-24 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

/* Raytracer framework */
uniform float blur=1.0; // extra blurriness to add
const float invalid_t=1.0e3; // far away
const float close_t=1.0e-2; // too close (behind head, self-intersection, etc)

/* This struct describes a ray, fattened to a cone */
struct ray_t {
	vec3 C; // start point of ray (typically the camera, hence the name C)
	vec3 D; // direction of ray 
	
	float r_start; // radius of cone at start of ray
	float r_per; // change in radius as a function of (unit) ray parameter T
};

/* Return the location along this ray at this t value. */
vec3 ray_at(ray_t ray,float t) {
	return ray.C+t*ray.D;
}

/* Return the radius of this ray at this t value. 
   The "abs" allows camera rays to narrow down, then expand again.
*/
float ray_radius(ray_t ray,float t) {
	return ray.r_start + abs(t*ray.r_per);
}



/* This struct describes how a surface looks */
struct material_t {
	float shiny; /* 0: totally matte surface; 1: big phong highlight */
	vec3 reflectance; /* diffuse color */
	float mirror; /* proportion of perfect mirror specular reflection (0.0 for non-mirror) */
	float density; /* if <1.0, object is volume rendered? */
};



/* This struct describes everything we know about a ray-object hit. */
struct ray_hit_t {
	vec3 P; /* world coords location of hit */
	vec3 N; /* surface normal of the hit */
	float t; /* ray t value at hit (or invalid_t if a miss) */
	float exit_t; /* where to continue world walk on a miss */
	float frac; /* fraction of ray that is covered by this object (0.0: none; 1.0: all)*/
	float shadowfrac; /* fraction of ray that is covered by all objects (0.0: none; 1.0: all)*/
	material_t m;
};

// Signed distance for a sphere centered at this location
float signed_distance_sphere(vec3 world,vec3 center,float r)
{
	return length(world-center)-r;
}
// Signed distance to a plate with normal along Z axis
float signed_distance_Zplate(vec3 world,float thick)
{
	return abs(world.z)-thick*0.5;
}

/* Return the value of the world distance field at this point. 
   A positive value is the distance to the nearest geometry. 
   A negative value means we're inside the geometry.
*/
float signed_distance(vec3 world)
{
	float d1=signed_distance_sphere(world,vec3(0),1.0);
	if (d1>1.0) return d1; //<- early exit (optimization)
	float d2=signed_distance_Zplate(world,1.5); 
	return max(d1,d2); // intersect plate and sphere
}



/* Return a ray_hit for this world ray.  
   Tests against all objects (in principle, could optimize though!). */
ray_hit_t world_hit(ray_t ray)
{
	ray_hit_t rh; rh.t=invalid_t; rh.frac=rh.shadowfrac=0.0;
	
	// Walk the ray along the distance field
	float t=close_t, t_step=0.1, min_step=0.01, max_t=10.0;
	for (int i=0;i<50;i++)
	{
		float d = signed_distance(ray_at(ray,t));
		if (d<=0.0) break; // now inside an object
		if (d>max_t-1.0) return rh; // missed everything
		t += d+min_step;
	}
	rh.t=t;
	rh.P=ray_at(ray,t);
	rh.m.shiny=0.0;
	rh.m.reflectance=vec3(1,1,1);
	rh.m.mirror=0.0;
	rh.m.density=1.0;
	rh.frac=1.0;
	
	return rh;
}

/* Compute the color of this surface at this ray hit */
vec3 shade_hit(inout ray_t ray, inout ray_hit_t rh)
{
	if (dot(rh.N,ray.D)>0.01) rh.N=-rh.N; // flip normal to face right way

	vec3 L=normalize(vec3(0.8,0.7,0.5));
	vec3 H=normalize(L+normalize(-ray.D));
	float specular=rh.m.shiny*pow(clamp(dot(H,rh.N),0.0,1.0),500.0);
	float diffuse=clamp(dot(rh.N,L),0.0,1.0);

	// check shadow ray 
	ray_t shadow_ray=ray_t(rh.P,L, ray_radius(ray,rh.t),blur*0.01);
	ray_hit_t shadow=world_hit(shadow_ray);
	if (shadow.t<invalid_t) {
		float illum=1.0-shadow.shadowfrac;
		diffuse*=illum; 
		specular*=illum; 
	}

	float ambient=0.05;
	return (ambient+diffuse)*rh.m.reflectance+specular*vec3(1.0);
}

/* Compute the world's color looking along this ray */
vec3 calc_world_color(ray_t ray) {
	vec3 skycolor=vec3(0.4,0.6,1.0); /* background color */
	vec3 color=vec3(0.0); /* color of this pixel */
	float frac=1.0; /* fraction of object light that makes it to the camera */

	const int maxbounce=5;
	for (int bounce=0;bounce<maxbounce;bounce++) 
	{
		ray.D=normalize(ray.D);
	/* Intersect camera ray with world geometry */
		ray_hit_t rh=world_hit(ray);

		if (rh.t>=invalid_t) { // escape to background
			color+=frac*skycolor; // sky color
			break; 
		}

	/* Do surface lighting */
		if (rh.m.density>1.0) { // solid surface 
			vec3 curObject=shade_hit(ray,rh);
			
			color+=frac*rh.frac*curObject;
			//color=rh.N; // debug: show surface normal at hit
		}
		
	/* Check for ray continuation */
		if (rh.frac<1.0) { // alpha: continue ray walk to composite background
			if (rh.m.mirror>0.0) { // uh oh, need two recursions
				// fake mirror with sky light (HACK!)
				color+=frac*rh.frac*rh.m.mirror*skycolor;
				//color+=vec3(1,0,0); 
			}
			frac*=(1.0-rh.frac); // attenuate by alpha
			
			float t=rh.exit_t+0.1;
			ray.r_start=ray_radius(ray,t);
			ray.C=ray_at(ray,t);
			// ray direction is unchanged, keep looking
		}
		else if (rh.m.mirror>0.0) { // mirror reflection
			frac*=rh.m.mirror; // attenuate by reflectance
			float t=rh.t;
			ray.r_start=ray_radius(ray,t);
			float glossy_blur=0.0; // nonzero for blurry reflections
			float inv_curve = 2.0; // FIXME: should be 1/curvature radius?
			ray.r_per=glossy_blur+inv_curve*ray.r_per; // blurry reflection
			
			ray.C=ray_at(ray,t);
			ray.D=reflect(ray.D,rh.N); // bounce off normal
		}
		else { // not alpha or mirror, we can stop
			break;
		}
		if (frac<0.005) { // any reflection will be <0.5% of final color
			return color;
		}
	} 
	
	return color;
}

void fragment() {
	vec3 world=(INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=INV_VIEW_MATRIX[3].xyz;
	
	vec3 C=world; // origin of ray (world coords, start at proxy geometry edge)
	vec3 D=normalize(world-camera); // direction of ray (world coords)
	float cone_width=blur*1.0/768.0;

	ray_t camera_ray=ray_t(C,D,0.0,cone_width);
	ALBEDO.rgb=1.6*calc_world_color(camera_ray);
	if (true)  // debug stuff
	{
		ALBEDO.rgb = vec3(signed_distance(world)); // distance field
		ray_hit_t rh=world_hit(camera_ray);
		if (rh.frac>0.5)
			ALBEDO.rgb = fract(rh.P);
	}
}

