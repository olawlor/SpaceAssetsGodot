# Demonstration rotation using vectors
# Dr. Orion Lawlor, lawlor@alaska.edu, 2022-09-06 (Public Domain)
extends Spatial

var t = 0 # Time since boot, in seconds
export var angriness = 1 # amount of change

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	var change = angriness*sin(2*t)
	
	# Write down a new coordinate system:
	transform.basis=Basis.IDENTITY  # same as parent
	transform.basis.x.y=change 
	transform.basis.y.x=-change
	
	# Fix scaling or skew by orthonormalizing:
	transform.basis=transform.basis.orthonormalized()
	
	pass
