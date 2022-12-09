extends Spatial

var direction = null # normalized direction vector
var damage = null # in hearts

func on_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		ALMain.GetPlayer().Damage(damage)

func _ready ():
	$Area2D.connect("body_entered", self, "on_body_entered")
	get_tree().create_timer(ALMain.BULLET_LIFETIME).connect("timeout", self, "queue_free")

func _process (delta):
	transform.origin += direction * ALMain.BULLET_SPEED * delta

func Init (_direction:Vector3, _damage:float):
	direction = _direction
	damage = _damage
