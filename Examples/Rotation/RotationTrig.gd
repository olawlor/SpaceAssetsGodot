# Demonstration rotation using trigonometry
# Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09-06 (Public Domain)
extends Spatial

var t = 0 # Time since boot, in seconds
export var angriness = 1.3 # angle in radians

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	var change = angriness*sin(2*t)
	
	# Use trig to compute new axes for a z rotation:
	var angle = change
	var c = cos(angle)
	var s = sin(angle)
	transform.basis.x=Vector3(c,s,0)
	transform.basis.y=Vector3(-s,c,0)
	
	pass
