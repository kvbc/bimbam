extends RigidBody

func Hit (dmg, dir : Vector2):
	apply_central_impulse(ALMain.Get2Dto3DVector(dir) * 5)
	return true
