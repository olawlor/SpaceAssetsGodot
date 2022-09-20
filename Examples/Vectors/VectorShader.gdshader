shader_type spatial;
//render_mode unshaded; //<- otherwise we need to mess with mesh normals

uniform vec4 axis; // 1 0 0 for X, 0 1 0 for Y, 0 0 1 for Z
// Build a coordinate system to rotate this vector into this direction.
vec3 point_at(vec3 src,vec3 target)
{
	vec3 newX=normalize(target); // make it have unit length
	vec3 newZ=normalize(cross(newX,vec3(0.01,1.0,-0.01))); // pick orientation
	vec3 newY=normalize(cross(newZ,newX)); // third axis must be this orientation
	newX *= length(target); // scale X so it's the original lengthd
	return src.x*newX + src.y*newY + src.z*newZ;
}


void vertex() 
{
	// Example vertex calculations
	float animate=TIME*0.2;
	vec3 myX=vec3(1,0,0);
	vec3 myY=vec3(sin(animate),cos(animate),0.0);
	vec3 myZ=cross(myX,myY);
	
	// Write my XYZ out to the direction for our vertex data
	vec3 point_dir = vec3(0,0,0);
	if (axis.x>0.99) point_dir=myX;  // X axis
	if (axis.y>0.99) point_dir=myY;  // Y axis
	if (axis.z>0.99) point_dir=myZ; // Z axis
	
	VERTEX=point_at(VERTEX,point_dir);
	NORMAL=point_at(NORMAL,point_dir);
}

void fragment()
{
	ALBEDO=axis.xyz;
}
