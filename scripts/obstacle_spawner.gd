extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer

var obstacle_scene: PackedScene = preload("res://scenes/obstacle.tscn")
var coin_scene: PackedScene = preload("res://scenes/coin.tscn")

var max_y_pos := -210.0
var min_y_pos := 120.0

# Gap between pipes is 600 units (top pipe at y-300, bottom at y+300 relative to obstacle)
# Coin spawns in the middle of that gap
var coin_spawn_chance := 0.17  # 17% chance a coin spawns with each pipe pair

func _on_spawn_timer_timeout() -> void:
	var obstacle = obstacle_scene.instantiate()
	add_child(obstacle)
	var obstacle_y = randf_range(max_y_pos, min_y_pos)
	obstacle.position.y = obstacle_y

	# Randomly spawn a coin in the gap between the pipes
	if randf() < coin_spawn_chance:
		var coin = coin_scene.instantiate()
		# Add to the game root (get_parent()) so coin spawns in world space
		get_parent().add_child(coin)
		# The gap center is exactly at the obstacle's world y position.
		# ObstacleSpawner is at y=400, obstacle_y is the local offset.
		# PipeTop is at obstacle_y - 300, PipeBottom at obstacle_y + 300 (local),
		# so the gap midpoint in world space = global_position.y + obstacle_y.
		coin.global_position = Vector2(global_position.x, global_position.y + obstacle_y)

func start() -> void:
	spawn_timer.start()

func stop() -> void:
	spawn_timer.stop()
