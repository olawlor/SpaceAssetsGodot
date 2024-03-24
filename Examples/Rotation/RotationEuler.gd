# Demonstrate using Euler angles to rotate a model
extends Node3D

var t = 0 # Time since boot, in seconds
@export var angriness = 90 # amount of change (degrees)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	var change = angriness*sin(2*t)
	
	rotation_degrees.x = change
	
	pass
