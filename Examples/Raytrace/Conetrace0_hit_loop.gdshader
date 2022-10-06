/*
A toy GLSL demonstration of "conetracing", a raytracing variant
that uses thicker cones instead of thin rays, which allows it to 
compute single-sample soft shadows, compute exact antialiased coverage,
and blurry shadows with a single sample.

The scene is hardcoded here, and generally just a toy demo implementation.

See the original SIGGRAPH 1984 paper "Ray Tracing with Cones" by John Amanatides,
or Cyril Crassin's Pacific Graphics 2011 "Interactive Indirect Illumination Using Voxel Cone Tracing".

This version uses adaptive pyramidal rendering to speed up display.

This Godot version modified from: 
	https://github.com/olawlor/directcompression/blob/master/conetrace/multigrid/fragment.txt
Dr. Orion Lawlor, lawlor@alaska.edu, 2021-10-05 (Public Domain)
*/
shader_type spatial;
render_mode cull_front; //<- keep only the back side of our proxy geometry
render_mode unshaded; //<- turn off Godot lighting


/********************* Conetracer utilities ***************/

/**
circleSliceArea:
Return the area of:
	 the portion of a circle, centered at the origin with radius 1, 
	 which has x-coordinate greater than frac.
	 -1<=frac<=1

i.e. return the area in #'s:

<pre>
    y
 
    ^
    |<---- 1 ---->|
_--------___
    |       -_         
    |        |\_        
    |        |##\         
    |        |###\       
    |        |####|       
    |        |####|    
----+--------+####+-----> x 
    |        |####| 
    |        |####|       
    |        |###/       
    |        |##/        
    |        |/        
_   |   ___--         
 -------
 -->|  frac  |<--
</pre>

This value is also equal to the integral
      / 1
      |
      | 2*sqrt(1-x^2) dx
      |
      / frac
(multiply by r^2 to get the area for a non-unit circle)
*/
float circleSliceArea(float frac)
{
	float half_pi=3.14159265358979/2.0;
	return (
		half_pi-
		frac*sqrt((1.0-frac)*(1.0+frac))-
		asin(frac)
		);
}

struct circleOverlap_t {
	float f1; // fraction of circle 1 overlapped by circle 2
	float f2; // fraction of circle 2 overlapped by circle 1
};

/*circleOverlap:
Given two circles with radii 1.0 and r2, 
with centers separated by a distance d, return 
the fraction f1 of circle 1 overlapped by circle 2, and 
the fraction f2 of circle 2 overlapped by circle 1.
*/
//(Version with r1 not fixed to 1.0)
circleOverlap_t circleOverlap(float r1,float r2,float d)
{
	circleOverlap_t r;
	if (r1+r2<=d) //Circles do not overlap at all
		{r.f1=0.0; r.f2=0.0;}
	else if (d+r2<=r1) //Circle 2 entirely in circle 1
		{r.f1=r2*r2/(r1*r1); r.f2=1.0;}
	else if (d+r1<=r2) //Circle 1 entirely in circle 2
		{r.f1=1.0; r.f2=r1*r1/(r2*r2);}
	else {
	//Circles partially overlap, creating a crescent shape
	//Compute the area of the circles
		float pi=3.14159265358979;
		float area1=r1*r1*pi;
		float area2=r2*r2*pi;
	//Compute area of overlap Region
		float alpha=(r1*r1+d*d-r2*r2)/(2.0*d);
		float beta=d-alpha;
		float area_overlap=r1*r1*circleSliceArea(alpha/r1)+
		                  r2*r2*circleSliceArea(beta/r2);
		r.f1=area_overlap/area1;
		r.f2=area_overlap/area2;
	}
	return r;
}



/***************************** shared vertex/fragment code *********************/

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


/* Return the t value where this ray hits 
    the sphere with this center and radius. */
void sphere_hit(inout ray_hit_t rh,ray_t ray,   // ray parameters
		vec3 center,float r, // object parameters
		material_t surface)  // shading parameters
{
	// solve for ray-object intersection via quadratic equation:
	//   0 = a*t^2 + b*t + c
	float a=dot(ray.D,ray.D);
	float b=2.0*dot(ray.C-center,ray.D);
	float closest_t=-b/(2.0*a); // ray T value at closest approach point
	float ray_rad=ray_radius(ray,closest_t); // radius at closest approach
	float center_to_center=length(ray_at(ray,closest_t)-center); // distance between centers
	circleOverlap_t overlap=circleOverlap(r,ray_rad,center_to_center);
	float rayFrac=min(overlap.f2,1.0);
	if (rayFrac==0.0) return; // ray misses completely
	
	float first_t, last_t;
	first_t=last_t=closest_t; // ray-object intersection point
	float c=dot(ray.C-center,ray.C-center)-r*r;
	float det=b*b-4.0*a*c;
	if (det>=0.0) { /* a real hit (not just a glancing edge hit) */
		float entr_t=(-b-sqrt(det))/(2.0*a); /* - intersection == entry point */
		float exit_t=(-b+sqrt(det))/(2.0*a); /* + intersection == exit point */
		if (entr_t>close_t) first_t=entr_t;
		if (exit_t>close_t) last_t=exit_t;
	}
	
	if (first_t<close_t) return; /* behind head */
	
	// Add shadow contribution regardless of sort order:
	// rh.shadowfrac=max(rh.shadowfrac,rayFrac);  // max shadows (weird voronoi look on boundaries)
	rh.shadowfrac=min(1.0,rh.shadowfrac+rayFrac);  // sum shadows (still looks a little weird)
	
	if (first_t>rh.t) return; /* beyond another object */
	
	vec3 P=ray_at(ray,first_t); // ray-object hit point (world coordinates)
	
	/* If we got here, we're the closest hit so far. */
	rh.m=surface;
	rh.t=first_t; // hit location
	rh.exit_t=last_t; /* continue walk from exit point */
	rh.P=P;
	rh.N=normalize(P-center); // sphere normal is easy!
	rh.frac=rayFrac; 
	
}

/* Return a ray_hit for this world ray.  
   Tests against all objects (in principle, could optimize though!). */
ray_hit_t world_hit(ray_t ray)
{
	ray_hit_t rh; rh.t=invalid_t; rh.frac=rh.shadowfrac=0.0;
	
// Intersect new ray with all the world's geometry:
	// Black camera sphere
	//sphere_hit(rh,ray, camera,0.2,
	//	 material_t(1.0,vec3(0.0,0.0,0.0),0.0,1.01));
	
	// Big brown sphere (dirt?)
	sphere_hit(rh,ray, vec3(0.0,-115.0,0.0),110.0,
		 material_t(1.0,vec3(0.4,0.3,0.2),0.0,1.01));
	
	// Little green sphere
	sphere_hit(rh,ray, vec3(0.0,-11.0,0.0),10.7,
		 material_t(1.0,vec3(0.2,0.6,0.4),0.3,1.01));

	// Wavy lines of floating red spheres
	float range=2.0;
	for (float i=-range;i<=range;i+=1.0) 
	for (float j=-range;j<=range;j+=1.0) 
	{
		vec2 loc=vec2(i*2.0,j*2.0);
		// float r=length(loc)/10.0; // around green sphere
		float z=abs(3.0*sin(i*j+0.3*TIME));
		vec3 color=vec3(0.5+0.5*i/range,0.3,0.5+0.5*j/range);
		float radius=0.5+1.0*fract(0.3*i*j);
		sphere_hit(rh,ray, 
			vec3(loc.x,z,loc.y),radius,
			 material_t(1.0,color,0.2,1.01));
	}
	
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
	vec3 world=(CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera=CAMERA_MATRIX[3].xyz;
	
	vec3 C=camera; // origin of ray (world coords)
	vec3 D=world-camera; // direction of ray (world coords)
	float cone_width=blur*1.0/768.0;
	ray_t camera_ray=ray_t(C,D,0.0,cone_width);

	ALBEDO.rgb=1.6*calc_world_color(camera_ray);
}

