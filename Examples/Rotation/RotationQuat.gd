# Demonstration rotation interpolation using quaternions
# Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09-06 (Public Domain)
extends Node3D

var t = 0 # Time since boot, in seconds

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	var change = 0.5+0.5*sin(2*t)
	
	var src = Quaternion(Vector3(0,0,0))
	var dst = Quaternion(Vector3(0,3.14,0))
	transform.basis=Basis(src.slerp(dst,change))
	pass
