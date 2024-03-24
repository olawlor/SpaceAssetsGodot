# Demonstration keyboard-driven rotation using coordinate vectors
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

	# Apply the rotations to our basis vectors:
	transform.basis.y += rot.x*transform.basis.z;
	transform.basis.z -= rot.x*transform.basis.y;
	transform.basis.z += rot.y*transform.basis.x;
	transform.basis.x -= rot.y*transform.basis.z;
	transform.basis.x += rot.z*transform.basis.y;
	transform.basis.y -= rot.z*transform.basis.x;
	
	# Fix up any scale change or skew
	transform.basis=transform.basis.orthonormalized()
	
	pass
