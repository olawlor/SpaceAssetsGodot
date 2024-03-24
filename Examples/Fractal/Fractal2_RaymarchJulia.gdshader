/*
Distance field based ray-object renderer.

Dr. Orion Lawlor, lawlor@alaska.edu, 2022-10-24 (Public Domain)
*/
shader_type spatial;
render_mode unshaded;

/* Raytracer framework */
const float blur=1.0; // extra blurriness to add
const float invalid_t=1.0e3; // far away
const float close_t=1.0e-2; // too close (behind head, self-intersection, etc)
const float shadow_start_t=0.03;

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
float signed_distance_slab(vec3 world,float r)
{
	return abs(world.z)-r;
}
// Signed distance to a plate with normal along Z axis
float signed_distance_Zplate(vec3 world,float thick)
{
	return abs(world.z)-thick*0.5;
}
// Signed distance to an axis-aligned box with this size.
//   From https://iquilezles.org/articles/distfunctions/
float signed_distance_box(vec3 world,vec3 size)
{
  vec3 q = abs(world) - size*0.5;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Signed distance to a gear shape, along the XY axis
uniform sampler2D gearDistance;
float signed_distance_gear(vec3 world)
{
	vec2 uv=vec2(world.x,world.y)*0.5-0.5;
	float pixel = textureLod(gearDistance,uv,0.5).r;
	return 0.5*(pixel - 0.5 - 0.01);
}



// Excellent commented quaternion julia code by Blake447:
//   https://www.shadertoy.com/view/tdt3W8
vec4 MultiplyQuaternions(vec4 a, vec4 b)
{
	float real = a.w*b.w - dot(a.xyz, b.xyz);  
    vec3 complex = (a.w*b.xyz + b.w*a.xyz + cross(a.xyz, b.xyz));
	return vec4(complex, real);
}

// Distance estimation for a julia set by Blake447, modified here:
float signed_distance_julia(vec3 p, vec4 seed)
{
    // First, offset the point by the center
	vec3 v = p;

    // Set C to be a vector of constants determining julia set we use
	vec4 C = seed;
    
    // Set Z to be some form of input from the vector
	//   Animate 4D slices of the shape
	vec4 Z = vec4(0.5*cos(0.1*TIME), v.x, v.y, v.z);
    
    // I'll be honest, I'm not entirely sure how the distance estimation works.
    // Calculate the derivative of Z. The Julia set we are using is Z^2 + C,
    // So this results in simply 2z
	vec4 dz = 2.0*Z + vec4(1.0, 1.0, 1.0, 1.0);

    // Run the iterative loop for some number of iterations
	for (int i = 0; i < 8; i++)
	{
        // Recalculate the derivative
		dz = 2.0 * MultiplyQuaternions(Z, dz) + vec4(1.0, 1.0, 1.0, 1.0);
        
        // Rcacalculate Z
		Z = MultiplyQuaternions(Z, Z) + C;
		//Z.g += 1.8*Z.b; //<- add some skew?!
        
       	// We rely on the magnitude of z being fairly large (the derivation includes
        // A limit as it approaches infinity) so we're going to let it run for a bit longer
        // after we know its going to explode. i.e. 1000 instead of the usual, like 8.
		if (dot(Z, Z) > 1000.0)
		{
			break;
		}
	}
    
    // And this is where the witchcraft happens. Again, not sure how this works, but as
   	// you can see, it does.
	float d = 0.5*sqrt(dot(Z, Z) / dot(dz, dz))*log(dot(Z, Z)) / log(10.0);
	
    // Return the distance estimation.
    return d;

}


/* Return the value of the world distance field at this point. 
   A positive value is the distance to the nearest geometry. 
   A negative value means we're inside the geometry.
*/
float signed_distance(vec3 world)
{
	float d1=signed_distance_sphere(world,vec3(0),2.0);
	if (d1>0.0) return d1;
	
	float d2=signed_distance_julia(world,
		vec4(0.33, 0.56, 0.0, -0.72)
		//vec4(0.0, -0.2, 0.0, -0.17) // solid block (closer to origin)
	);
	return d2;
}

/* Estimate the surface normal of the signed_distance at this point */
vec3 signed_distance_normal(vec3 world)
{
	float del=0.01; // delta value for computing slopes
	return normalize(vec3(
		signed_distance(world+vec3(del,0,0))-signed_distance(world-vec3(del,0,0)),
		signed_distance(world+vec3(0,del,0))-signed_distance(world-vec3(0,del,0)),
		signed_distance(world+vec3(0,0,del))-signed_distance(world-vec3(0,0,del))
	));
}

/* Return a ray_hit for this world ray.  
   Tests against all objects (in principle, could optimize though!). */
ray_hit_t world_hit(ray_t ray)
{
	ray_hit_t rh; rh.t=invalid_t; rh.frac=rh.shadowfrac=0.0;
	
	// Walk the ray along the distance field
	float t=close_t, min_step=0.00001, max_t=10.0;
	for (int i=0;i<1000;i++)
	{
		float d = signed_distance(ray_at(ray,t));
		if (d<=0.0) break; // now inside an object
		if (d>max_t-1.0) return rh; // missed everything
		t += 1.0*d+min_step;
	}
	rh.t=t;
	rh.P=ray_at(ray,t);
	rh.N=signed_distance_normal(rh.P);
	rh.m.shiny=0.5;
	rh.m.reflectance=0.3*vec3(1,1,1);
	rh.m.mirror=0.0; // 4;
	rh.m.density=1.0;
	rh.frac=1.0;
	rh.shadowfrac=1.0;
	
	return rh;
}

/* Compute the color of this surface at this ray hit */
vec3 shade_hit(inout ray_t ray, inout ray_hit_t rh)
{
	if (dot(rh.N,ray.D)>0.01) rh.N=-rh.N; // flip normal to face right way

	vec3 L=normalize(vec3(0.8,0.7,0.5));
	vec3 H=normalize(L+normalize(-ray.D));
	float specular=rh.m.shiny*pow(clamp(dot(H,rh.N),0.0,1.0),500.0);
	float diffuse=clamp(dot(rh.N,L),0.0,0.8);

	if (true) // check shadow ray 
	{
		ray_t shadow_ray=ray_t(rh.P+shadow_start_t*rh.N,L, ray_radius(ray,rh.t),blur*0.01);
		ray_hit_t shadow=world_hit(shadow_ray);
		if (shadow.t<invalid_t) {
			float illum=1.0-shadow.shadowfrac;
			diffuse*=illum; 
			specular*=illum; 
		}
	}

	float ambient=0.1;
	return (ambient+diffuse)*rh.m.reflectance+specular*vec3(1.0);
}

/* Compute the world's color looking along this ray */
vec3 calc_world_color(ray_t ray) {
	vec3 skycolor=vec3(0.4,0.6,1.0); /* background color */
	vec3 color=vec3(0.0); /* color of this pixel */
	float frac=1.0; /* fraction of object light that makes it to the camera */

	const int maxbounce=3;
	for (int bounce=0;bounce<maxbounce;bounce++) 
	{
		ray.D=normalize(ray.D);
	/* Intersect camera ray with world geometry */
		ray_hit_t rh=world_hit(ray);

		if (rh.frac==0.0) { // escape to background
			color+=frac*skycolor; // sky color
			break; 
		}

	/* Do surface lighting */
		if (rh.m.density>0.5) { // solid surface 
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
			
			ray.C=ray_at(ray,t)+shadow_start_t*rh.N; // move off surface
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
	if (false)  // debug stuff
	{
		ALBEDO.rgb = fract(4.0*vec3(signed_distance(world))); // distance field
		ray_hit_t rh=world_hit(camera_ray);
		if (rh.frac>0.5)
		{
			ALBEDO.rgb = fract(rh.P); // world position
			//ALBEDO.rgb = rh.N; // normal
		}
	}
}

