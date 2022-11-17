extends Node2D

var dir_exit = {}

func on_exit_entered (body, area, method):
	if ALMain.IsBodyPlayer(body):
		ALMain.call(method)

func create_exit (dir, tilemap, move_method):
	var rect = tilemap.get_used_rect()
	rect.size *= tilemap.cell_size
	rect.position *= tilemap.cell_size
	
	var exit = Area2D.new()
	exit.position = rect.position + rect.size / 2
	exit.name = tilemap.name
	var cs = CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cs.shape.extents = rect.size / 2
	exit.add_child(cs)
	$Exits.add_child(exit)
	exit.connect("body_entered", self, "on_exit_entered", [exit, move_method])
	dir_exit[dir] = exit

func has_exit (dir):
	if (dir == ALMain.Dir.LEFT ): return not $Exit_Tilemaps/Left .get_used_cells().empty()
	if (dir == ALMain.Dir.RIGHT): return not $Exit_Tilemaps/Right.get_used_cells().empty()
	if (dir == ALMain.Dir.UP   ): return not $Exit_Tilemaps/Up   .get_used_cells().empty()
	if (dir == ALMain.Dir.DOWN ): return not $Exit_Tilemaps/Down .get_used_cells().empty()

func _ready ():
	var bullets = Node2D.new()
	bullets.name = "Bullets"
	add_child(bullets)
	
	var exits = Node2D.new()
	exits.name = "Exits"
	add_child(exits)
	
	var enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	
	if has_node("EnemySpawns"):
		for enemy_group in $EnemySpawns.get_children():
			for pos2d in enemy_group.get_children():
				var enemy = preload("res://Scenes/Enemy.tscn").instance()
				enemy.global_position = pos2d.global_position
				enemy.Init(ALMain.EnemyNameToType(enemy_group.name))
				enemies.add_child(enemy)

func SpawnBullet (pos:Vector2, velocity:Vector2, damage:int):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	bullet.global_position = pos
	bullet.Init(velocity, damage)
	$Bullets.add_child(bullet)

func GetExitPosition (dir):
	return dir_exit[dir].global_position

func InitRoom (on_left, on_right, on_up, on_down):
	if (on_left  and has_exit(ALMain.Dir.LEFT )): create_exit(ALMain.Dir.LEFT,  $Exit_Tilemaps/Left,  "MoveLeft")
	if (on_right and has_exit(ALMain.Dir.RIGHT)): create_exit(ALMain.Dir.RIGHT, $Exit_Tilemaps/Right, "MoveRight")
	if (on_up    and has_exit(ALMain.Dir.UP   )): create_exit(ALMain.Dir.UP,    $Exit_Tilemaps/Up,    "MoveTop")
	if (on_down  and has_exit(ALMain.Dir.DOWN )): create_exit(ALMain.Dir.DOWN,  $Exit_Tilemaps/Down,  "MoveBottom")
