extends Node2D

var velocity
var damage # in hearts

func on_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		ALMain.GetPlayer().Damage(damage)

func _ready ():
	$Area2D.connect("body_entered", self, "on_body_entered")
	get_tree().create_timer(ALMain.BULLET_LIFETIME).connect("timeout", self, "queue_free")

func _process (delta):
	position += velocity * ALMain.BULLET_SPEED * delta

func Init (_velocity:Vector2, _damage:float):
	velocity = _velocity
	damage = _damage
