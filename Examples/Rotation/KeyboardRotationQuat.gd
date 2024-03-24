# Demonstration keyboard-driven rotation using quaternions
# Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09-06 (Public Domain)
extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rot=Vector3(0,0,0) # XYZ rotation amount (radians)
	var speed=1.0*delta   # radians/frame rotation speed
	
	# Convert WASDEQ to rotations (like a flight sim, or Kerbal Space Program)
	if Input.is_physical_key_pressed(KEY_W):
		rot.x=+speed
	if Input.is_physical_key_pressed(KEY_S):
		rot.x=-speed
	if Input.is_physical_key_pressed(KEY_E):
		rot.z=+speed
	if Input.is_physical_key_pressed(KEY_Q):
		rot.z=-speed
	if Input.is_physical_key_pressed(KEY_A):
		rot.y=+speed
	if Input.is_physical_key_pressed(KEY_D):
		rot.y=-speed
	
	# Get our current rotation as a quaternion
	var cur : Quaternion=transform.basis.get_rotation_quaternion()
	var qrot = Quaternion(rot) # convert rotation to quaternion
	# cur = qrot*cur  # apply rotation in world space
	cur = cur*qrot  # apply rotation in local space
	transform.basis=Basis(cur) # write back to object
	
	pass

