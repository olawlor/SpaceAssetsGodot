# Demonstration WASD motion and mouse look
# Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09-08 (Public Domain)
extends Spatial

var last_pos = Vector2(-1,-1) # pixels where mouse last seen

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rot=Vector3(0,0,0) # XYZ rotation amount (radians)
	var move=Vector3(0,0,0) # local XYZ motion
	var speed=5.0*delta   # meters/frame motion speed
	
	# Rotate based on mouse look
	var cur_pos = get_viewport().get_mouse_position()
	var dpos = cur_pos - last_pos
	if (last_pos.x==-1):
		dpos = Vector2(0,0)
	last_pos = cur_pos
	var mouse_speed=0.01; # radians / pixel
	if Input.is_mouse_button_pressed(2): # right click
		rot.y += -mouse_speed * dpos.x;
		rot.x += -mouse_speed * dpos.y;
	
	# Convert WASDEQ to motion (like minecraft)
	if Input.is_physical_key_pressed(KEY_W):
		move.z += -speed
	if Input.is_physical_key_pressed(KEY_S):
		move.z += +speed
	if Input.is_physical_key_pressed(KEY_E):
		move.y += +speed
	if Input.is_physical_key_pressed(KEY_Q):
		move.y += -speed
	if Input.is_physical_key_pressed(KEY_A):
		move.x += -speed
	if Input.is_physical_key_pressed(KEY_D):
		move.x += +speed
	transform.origin += move.x*transform.basis.x;
	transform.origin += move.y*transform.basis.y;
	transform.origin += move.z*transform.basis.z;

	# Apply the rotations to our basis vectors:
	transform.basis.y += rot.x*transform.basis.z;
	transform.basis.z -= rot.x*transform.basis.y;
	transform.basis.z += rot.y*transform.basis.x;
	transform.basis.x -= rot.y*transform.basis.z;
	
	#var fix_tilt = transform.basis.y.x; # radians of rotation 
	#rot.z += fix_tilt
	transform.basis.x += rot.z*transform.basis.y;
	transform.basis.y -= rot.z*transform.basis.x;
	
	
	# Fix up any scale change or skew
	transform.basis=transform.basis.orthonormalized()
	
	pass
