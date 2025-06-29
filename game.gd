extends Node2D

@export var game_area_width = 10
@export var game_area_height = 20

var brick_layer: TileMapLayer = null
var next_brick_layer: TileMapLayer = null
var brick_grid = []
var next_brick_shape_type: BrickShape = BrickShape.SHAPE_NULL
var next_brick_tile_type: int = -1
var current_brick_shape_type: BrickShape = BrickShape.SHAPE_NULL
var current_brick_tile_type: int = -1
var current_brick_pivot_pos = -Vector2i.ONE
var current_brick_direction = Vector2i.UP
var current_game_state: GameState = GameState.IDLE
var score = 0

enum GameState {
	IDLE, SPAWN, FALL, CLEAR
}

# 砖块类型
enum BrickShape {
	SHAPE_O, SHAPE_I, SHAPE_L, SHAPE_J, SHAPE_S, SHAPE_Z, SHAPE_T, SHAPE_NULL
}

var brick_shape_arr = [
	BrickShape.SHAPE_O, BrickShape.SHAPE_I, BrickShape.SHAPE_L, BrickShape.SHAPE_J,
	BrickShape.SHAPE_S, BrickShape.SHAPE_Z, BrickShape.SHAPE_T
]

# 砖块对应tile坐标
var brick_tile_arr: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0),
	Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1), Vector2i(6,1)
]

func set_next_brick_layer_brick(shape_type: BrickShape, tile_type: int):
	next_brick_layer.clear()
	match shape_type:
		BrickShape.SHAPE_O:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(0, 1), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 1), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_I:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(3, 0), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_L:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(0, 1), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_J:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 1), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_S:
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(0, 1), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 1), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_Z:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 1), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 1), 0, brick_tile_arr[tile_type], 0)
		BrickShape.SHAPE_T:
			next_brick_layer.set_cell(Vector2i(0, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(2, 0), 0, brick_tile_arr[tile_type], 0)
			next_brick_layer.set_cell(Vector2i(1, 1), 0, brick_tile_arr[tile_type], 0)

func spawn_fallen_brick(shape_type: BrickShape, tile_type: int):
	current_brick_direction = Vector2i.UP
	current_brick_shape_type = shape_type
	current_brick_tile_type = tile_type
	match shape_type:
		BrickShape.SHAPE_O:
			## 0 1
			## 1 1
			current_brick_pivot_pos = Vector2i(4, 0)
			brick_grid[4][0] = tile_type
			brick_grid[4][1] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[5][1] = tile_type
		BrickShape.SHAPE_I:
			##            1
			## 1 0 1 1 => 0
			##            1
			##            1
			current_brick_pivot_pos = Vector2i(4, 0)
			brick_grid[3][0] = tile_type
			brick_grid[4][0] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[6][0] = tile_type
		BrickShape.SHAPE_L:
			## 0 1 1    1 0        1    1
			## 1     =>   1 => 1 1 0 => 1
			##            1             0 1
			current_brick_pivot_pos = Vector2i(3, 0)
			brick_grid[3][0] = tile_type
			brick_grid[4][0] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[3][1] = tile_type
		BrickShape.SHAPE_J:
			## 1 1 0      1    1        0 1
			##     1 =>   1 => 0 1 1 => 1
			##          1 0             1
			current_brick_pivot_pos = Vector2i(5, 0)
			brick_grid[3][0] = tile_type
			brick_grid[4][0] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[5][1] = tile_type
		BrickShape.SHAPE_S:
			##   1 1    1      
			## 1 0   => 0 1
			##            1    
			current_brick_pivot_pos = Vector2i(4, 1)
			brick_grid[4][0] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[3][1] = tile_type
			brick_grid[4][1] = tile_type
		BrickShape.SHAPE_Z:
			## 1 1        1    
			##   0 1 => 0 1
			##          1     
			current_brick_pivot_pos = Vector2i(4, 1)
			brick_grid[3][0] = tile_type
			brick_grid[4][0] = tile_type
			brick_grid[4][1] = tile_type
			brick_grid[5][1] = tile_type
		BrickShape.SHAPE_T:
			##            1      1      1
			## 1 0 1 => 1 0 => 1 0 1 => 0 1
			##   1        1             1
			current_brick_pivot_pos = Vector2i(4, 0)
			brick_grid[3][0] = tile_type
			brick_grid[4][0] = tile_type
			brick_grid[5][0] = tile_type
			brick_grid[4][1] = tile_type


func update_brick_layer():
	brick_layer.clear()
	for x in range(game_area_width):
		for y in range(game_area_height):
			if brick_grid[x][y] != -1:
				brick_layer.set_cell(Vector2i(x, y), 0, brick_tile_arr[brick_grid[x][y]], 0)

func init_brick_grid():
	brick_grid.resize(game_area_width)
	for x in range(game_area_width):
		brick_grid[x] = []
		brick_grid[x].resize(game_area_height)
		brick_grid[x].fill(-1)

func spawn_next_brick():
	next_brick_shape_type = brick_shape_arr.pick_random()
	next_brick_tile_type = randi() % brick_tile_arr.size()
	set_next_brick_layer_brick(next_brick_shape_type, next_brick_tile_type)	

func update_brick_layer_by_fall():
	update_brick_layer()

func check_is_fall_to_end() -> bool:
	return false

func check_is_clear_avail() -> bool:
	return false

func clear_brick_lines() -> bool:
	return false

func state_change_process():
	print("current_game_state: " + str(current_game_state))
	match current_game_state:
		GameState.IDLE:
			pass
		GameState.SPAWN:
			spawn_fallen_brick(next_brick_shape_type, next_brick_tile_type)
			spawn_next_brick()
			current_game_state = GameState.FALL
		GameState.FALL:
			if check_is_fall_to_end():
				current_game_state = GameState.CLEAR
			else:
				update_brick_layer_by_fall()
		GameState.CLEAR:
			if check_is_clear_avail():
				clear_brick_lines()
			else:
				current_game_state = GameState.SPAWN

func start_game():
	init_brick_grid()
	brick_layer.clear()
	next_brick_layer.clear()
	spawn_next_brick()
	current_game_state = GameState.SPAWN

func _ready() -> void:
	brick_layer = $BrickBasePosition/BrickLayer
	next_brick_layer = $NextBrickBasePosition/NextBrickLayer
	current_game_state = GameState.IDLE
	start_game()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		pass
	elif event.is_action_pressed("ui_right"):
		pass
	elif event.is_action_pressed("ui_up"):
		pass
	elif event.is_action_pressed("ui_down"):
		pass

func _on_update_timer_timeout() -> void:
	state_change_process()
