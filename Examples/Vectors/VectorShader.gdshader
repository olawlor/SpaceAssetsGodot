/*
  Displays a 3D solid vector, for getting a better understanding of 
  vector and matrix math. 
  Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09 (Public Domain)
*/
shader_type spatial;

uniform vec4 axis; // 1 0 0 for X, 0 1 0 for Y, 0 0 1 for Z
// Build a coordinate system to rotate this vector into this direction.
vec3 point_at(vec3 src,vec3 target)
{
	vec3 newX=normalize(target); // make it have unit length
	vec3 newZ=normalize(cross(newX,vec3(0.01,1.0,-0.0))); // pick orientation
	vec3 newY=normalize(cross(newZ,newX)); // third axis must be this orientation
	newX *= length(target); // scale X so it's the original lengthd
	return src.x*newX + src.y*newY + src.z*newZ;
}


void vertex() 
{
	// Example vertex calculations
	float animate=TIME*0.2;
	vec3 myR=vec3(1,0,0);
	vec3 myG=vec3(sin(animate),cos(animate),0.0);
	vec3 myB=cross(myR,myG);
	vec3 myW=cross(myG,myR);
	
	// Write my XYZ out to the direction for our vertex data
	vec3 myDir = vec3(0,0,0);
	vec3 myOrigin = WORLD_MATRIX[3].xyz; 
	if (axis.x>0.99) {myDir=myR;} // R/X axis
	if (axis.y>0.99) {myDir=myG;} // G/Y axis
	if (axis.z>0.99) {myDir=myB;} // B/Z axis
	if (axis.w>0.99) {myDir=myW;} // A/W axis
	
	vec3 world=point_at(VERTEX,myDir) + myOrigin;
	NORMAL=point_at(NORMAL,myDir);
	
	// Project our world coordinates onscreen:
	POSITION=PROJECTION_MATRIX*INV_CAMERA_MATRIX*vec4(world,1.0);
}

void fragment()
{
	ALBEDO=axis.xyz;
}
