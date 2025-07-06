extends Node2D

const UNABLE_INT: int = -1
const UNABLE_POS: Vector2i = -Vector2i.ONE

@export var game_area_width = 10
@export var game_area_height = 20

var brick_layer: TileMapLayer = null
var next_brick_layer: TileMapLayer = null
var brick_grid = []
var next_brick_shape_type: BrickShape = BrickShape.SHAPE_NULL
var next_brick_tile_type: int = UNABLE_INT
var current_brick_shape_type: BrickShape = BrickShape.SHAPE_NULL
var current_brick_tile_type: int = UNABLE_INT
var current_brick_pivot_pos = UNABLE_POS
var current_brick_direction = Vector2i.UP
var current_game_state: GameState = GameState.IDLE
var stop_input_flag: bool = false
var game_score = 0

# 游戏状态
enum GameState {
	IDLE, SPAWN, FALL, CLEAR
}

# 砖块类型
enum BrickShape {
	SHAPE_O, SHAPE_I, SHAPE_L, SHAPE_J, SHAPE_S, SHAPE_Z, SHAPE_T, SHAPE_NULL
}

# 砖块类型值数组，用于随机取值
# L形和J形算一类，S形和J形算一类，为保证抽取概率平等，其他O,I,T形都有两个值
var brick_shape_arr = [
	BrickShape.SHAPE_O, BrickShape.SHAPE_O, 
	BrickShape.SHAPE_I, BrickShape.SHAPE_I, 
	BrickShape.SHAPE_L, BrickShape.SHAPE_J,
	BrickShape.SHAPE_S, BrickShape.SHAPE_Z, 
	BrickShape.SHAPE_T, BrickShape.SHAPE_T
]

# 砖块对应tile坐标
var brick_tile_arr: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0),
	Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1), Vector2i(4,1), Vector2i(5,1), Vector2i(6,1)
]

## 设置下一个生成的砖块的图像
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

## 设置下落的砖块
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

## 更新砖块图像层
func update_brick_layer():
	brick_layer.clear()
	for x in range(game_area_width):
		for y in range(game_area_height):
			if brick_grid[x][y] != UNABLE_INT:
				brick_layer.set_cell(Vector2i(x, y), 0, brick_tile_arr[brick_grid[x][y]], 0)

## 初始化砖块数组
func init_brick_grid():
	brick_grid.resize(game_area_width)
	for x in range(game_area_width):
		brick_grid[x] = []
		brick_grid[x].resize(game_area_height)
		brick_grid[x].fill(UNABLE_INT)

## 生成下一个砖块
func spawn_next_brick():
	next_brick_shape_type = brick_shape_arr.pick_random()
	next_brick_tile_type = randi() % brick_tile_arr.size()
	set_next_brick_layer_brick(next_brick_shape_type, next_brick_tile_type)	

## 根据下落过程更新砖块层，调用前需先用check_is_fall_to_end函数确认
func update_brick_layer_by_fall():
	var x = current_brick_pivot_pos.x
	var y = current_brick_pivot_pos.y
	current_brick_pivot_pos = Vector2i(x, y+1)
	match current_brick_shape_type:
		BrickShape.SHAPE_O:
			## 0 1
			## 1 1
			brick_grid[x][y+2] = current_brick_tile_type
			brick_grid[x+1][y+2] = current_brick_tile_type
			brick_grid[x][y] = UNABLE_INT
			brick_grid[x+1][y] = UNABLE_INT
		BrickShape.SHAPE_I:
			##            1
			## 1 0 1 1 => 0
			##            1
			##            1
			if current_brick_direction == Vector2i.UP:
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x+2][y+1] = current_brick_tile_type
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
				brick_grid[x+2][y] = UNABLE_INT
			else:
				brick_grid[x][y+3] = current_brick_tile_type
				brick_grid[x][y-1] = UNABLE_INT
		BrickShape.SHAPE_L:
			## 0 1 1    1 0        1    1
			## 1     =>   1 => 1 1 0 => 1
			##            1             0 1
			if current_brick_direction == Vector2i.UP:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x+2][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
				brick_grid[x+2][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				brick_grid[x][y+3] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x-1][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x-2][y+1] = current_brick_tile_type
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x-2][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x][y-2] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
		BrickShape.SHAPE_J:
			## 1 1 0      1    1        0 1
			##     1 =>   1 => 0 1 1 => 1
			##          1 0             1
			if current_brick_direction == Vector2i.UP:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x-2][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x-2][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x][y-2] = UNABLE_INT
				brick_grid[x-1][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x+2][y+1] = current_brick_tile_type
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
				brick_grid[x+2][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				brick_grid[x][y+3] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
		BrickShape.SHAPE_S:
			##   1 1    1      
			## 1 0   => 0 1
			##            1  
			if current_brick_direction == Vector2i.UP:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x+1][y] = current_brick_tile_type
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x+1][y-1] = UNABLE_INT
			else:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+2] = current_brick_tile_type
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
		BrickShape.SHAPE_Z:
			## 1 1        1    
			##   0 1 => 0 1
			##          1  
			if current_brick_direction == Vector2i.UP:
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x-1][y] = current_brick_tile_type
				brick_grid[x+1][y] = UNABLE_INT
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x-1][y-1] = UNABLE_INT
			else:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x+1][y-1] = UNABLE_INT
		BrickShape.SHAPE_T:
			##            1      1      1
			## 1 0 1 => 1 0 => 1 0 1 => 0 1
			##   1        1             1
			if current_brick_direction == Vector2i.UP:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x][y-1] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x][y+1] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x-1][y] = UNABLE_INT
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				brick_grid[x][y+2] = current_brick_tile_type
				brick_grid[x+1][y+1] = current_brick_tile_type
				brick_grid[x][y-1] = UNABLE_INT
				brick_grid[x+1][y] = UNABLE_INT
	update_brick_layer()

## 判断砖块是否下落到底
func check_is_fall_to_end() -> bool:
	var x = current_brick_pivot_pos.x
	var y = current_brick_pivot_pos.y
	match current_brick_shape_type:
		BrickShape.SHAPE_O:
			## 0 1
			## 1 1
			if y + 2 >= game_area_height or \
				brick_grid[x][y+2] != UNABLE_INT or \
				brick_grid[x+1][y+2] != UNABLE_INT:
				return true
		BrickShape.SHAPE_I:
			##            1
			## 1 0 1 1 => 0
			##            1
			##            1
			if current_brick_direction == Vector2i.UP:
				if y + 1 >= game_area_height or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT or \
					brick_grid[x+2][y+1] != UNABLE_INT:
					return true
			else:
				if y + 3 >= game_area_height or \
					brick_grid[x][y+3] != UNABLE_INT:
					return true
		BrickShape.SHAPE_L:
			## 0 1 1    1 0        1    1
			## 1     =>   1 => 1 1 0 => 1
			##            1             0 1
			if current_brick_direction == Vector2i.UP:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT or \
					brick_grid[x+2][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.RIGHT:
				if y + 3 >= game_area_height or \
					brick_grid[x][y+3] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.DOWN:
				if y + 1 >= game_area_height or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.LEFT:
				if y + 1 >= game_area_height or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
		BrickShape.SHAPE_J:
			## 1 1 0      1    1        0 1
			##     1 =>   1 => 0 1 1 => 1
			##          1 0             1
			if current_brick_direction == Vector2i.UP:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x-2][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.RIGHT:
				if y + 1 >= game_area_height or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.DOWN:
				if y + 1 >= game_area_height or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT or \
					brick_grid[x+2][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.LEFT:
				if y + 3 >= game_area_height or \
					brick_grid[x][y+3] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
		BrickShape.SHAPE_S:
			##   1 1    1      
			## 1 0   => 0 1
			##            1  
			if current_brick_direction == Vector2i.UP:
				if y + 1 >= game_area_height or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y] != UNABLE_INT:
						return true
			else:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+2] != UNABLE_INT:
						return true
		BrickShape.SHAPE_Z:
			## 1 1        1    
			##   0 1 => 0 1
			##          1  
			if current_brick_direction == Vector2i.UP:
				if y + 1 >= game_area_height or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT or \
					brick_grid[x-1][y] != UNABLE_INT:
						return true
			else:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
		BrickShape.SHAPE_T:
			##            1      1      1
			## 1 0 1 => 1 0 => 1 0 1 => 0 1
			##   1        1             1
			if current_brick_direction == Vector2i.UP:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.RIGHT:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT:
						return true 
			elif current_brick_direction == Vector2i.DOWN:
				if y + 1 >= game_area_height or \
					brick_grid[x-1][y+1] != UNABLE_INT or \
					brick_grid[x][y+1] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true
			elif current_brick_direction == Vector2i.LEFT:
				if y + 2 >= game_area_height or \
					brick_grid[x][y+2] != UNABLE_INT or \
					brick_grid[x+1][y+1] != UNABLE_INT:
						return true 
	return false

## 判断是否可以清除行
func check_is_clear_avail() -> bool:
	var is_all_fill = true
	for y in range(game_area_height-1, -1, -1):
		is_all_fill = true
		for x in range(game_area_width):
			if brick_grid[x][y] == UNABLE_INT:
				is_all_fill = false
		if is_all_fill == true:
			return true
	return false

## 从最底下开始清除一行
func clear_brick_line_from_bottom():
	var is_all_fill: bool = true
	var clear_line_y = UNABLE_INT
	# 找到被消除行
	for y in range(game_area_height - 1, -1, -1):
		is_all_fill = true
		for x in range(game_area_width):
			if brick_grid[x][y] == UNABLE_INT:
				is_all_fill = false
		if is_all_fill == true:
			clear_line_y = y
			break
	if clear_line_y == UNABLE_INT:
		return
	# 消除行
	for x in range(game_area_width):
		brick_grid[x][clear_line_y] = UNABLE_INT
	update_brick_layer()
	# 等待短暂时间
	await get_tree().create_timer(0.3).timeout
	# 消除行之上的砖块全部向下移动一格
	for y in range(clear_line_y, 0, -1):
		for x in range(game_area_width):
			brick_grid[x][y] = brick_grid[x][y-1]
	for x in range(game_area_width):
		brick_grid[x][0] = UNABLE_INT
	update_brick_layer()

## 处理向左或向右移动的动作
func handle_move_left_or_right_action(move_direction: Vector2i):
	if move_direction != Vector2i.LEFT and move_direction != Vector2i.RIGHT:
		return
	var x = current_brick_pivot_pos.x
	var y = current_brick_pivot_pos.y
	match current_brick_shape_type:
		BrickShape.SHAPE_O:
			## 0 1
			## 1 1
			if move_direction == Vector2i.LEFT:
				if x <= 0 or \
					brick_grid[x-1][y] != UNABLE_INT or \
					brick_grid[x-1][y+1] != UNABLE_INT:
					return
				brick_grid[x-1][y] = current_brick_tile_type
				brick_grid[x-1][y+1] = current_brick_tile_type
				brick_grid[x+1][y] = UNABLE_INT
				brick_grid[x+1][y+1] = UNABLE_INT
			elif move_direction == Vector2i.RIGHT:
				if x >= game_area_width - 2 or \
					brick_grid[x+2][y] != UNABLE_INT or \
					brick_grid[x+2][y+1] != UNABLE_INT:
					return
				brick_grid[x+2][y] = current_brick_tile_type
				brick_grid[x+2][y+1] = current_brick_tile_type
				brick_grid[x][y] = UNABLE_INT
				brick_grid[x][y+1] = UNABLE_INT
		BrickShape.SHAPE_I:
			##            1
			## 1 0 1 1 => 0
			##            1
			##            1
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x+2][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 3 or \
						brick_grid[x+3][y] != UNABLE_INT:
						return
					brick_grid[x+3][y] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
			else:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y-1] != UNABLE_INT or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT or \
						brick_grid[x-1][y+2] != UNABLE_INT:
						return
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x-1][y+2] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+1][y+2] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+1][y+2] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
		BrickShape.SHAPE_L:
			## 0 1 1    1 0        1    1
			## 1     =>   1 => 1 1 0 => 1
			##            1             0 1
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x+2][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 3 or \
						brick_grid[x+3][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT:
						return
					brick_grid[x+3][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT or \
						brick_grid[x-1][y+2] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x-1][y+2] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+1][y+2] != UNABLE_INT:
						return
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+1][y+2] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				if move_direction == Vector2i.LEFT:
					if x <= 2 or \
						brick_grid[x-3][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-3][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT:
						return
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x-2][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y-1] != UNABLE_INT or \
						brick_grid[x-1][y-2] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x-1][y-2] = current_brick_tile_type
					brick_grid[x+1][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y-2] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+2][y] != UNABLE_INT or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+1][y-2] != UNABLE_INT:
						return
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+1][y-2] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y-2] = UNABLE_INT
		BrickShape.SHAPE_J:
			## 1 1 0      1    1        0 1
			##     1 =>   1 => 0 1 1 => 1
			##          1 0             1
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 2 or \
						brick_grid[x-3][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-3][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y]  != UNABLE_INT or \
						brick_grid[x+1][y+1]  != UNABLE_INT:
						return
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x-2][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x][y-1] != UNABLE_INT or \
						brick_grid[x][y-2] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x][y-1] = current_brick_tile_type
					brick_grid[x][y-2] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y-2] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+1][y-2] != UNABLE_INT:
						return
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+1][y-2] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y-2] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x+2][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 3 or \
						brick_grid[x+3][y] != UNABLE_INT or \
						brick_grid[x+1][y-1] != UNABLE_INT:
						return
					brick_grid[x+3][y] = current_brick_tile_type
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT or \
						brick_grid[x-1][y+2] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x-1][y+2] = current_brick_tile_type
					brick_grid[x+1][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+2][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+1][y+2] != UNABLE_INT:
						return
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+1][y+2] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x][y+2] = UNABLE_INT
		BrickShape.SHAPE_S:
			##   1 1    1      
			## 1 0   => 0 1
			##            1  
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x-1][y-1] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x+1][y-1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+2][y-1] != UNABLE_INT:
						return
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+2][y-1] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
			else:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y-1] != UNABLE_INT or \
						brick_grid[x][y+1] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x][y+1] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x+1][y] = UNABLE_INT
					brick_grid[x+1][y+1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT or \
						brick_grid[x+2][y+1] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x+2][y+1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x+1][y+1] = UNABLE_INT
		BrickShape.SHAPE_Z:
			## 1 1        1    
			##   0 1 => 0 1
			##          1  
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y-1] != UNABLE_INT or \
						brick_grid[x-1][y] != UNABLE_INT:
						return
					brick_grid[x-2][y-1] = current_brick_tile_type
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x+1][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = UNABLE_INT
					brick_grid[x][y] = UNABLE_INT
			else: 
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT or \
						brick_grid[x][y+1] != UNABLE_INT:
						return
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y+1] = current_brick_tile_type
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x+1][y] = UNABLE_INT
					brick_grid[x+1][y-1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT or \
						brick_grid[x+2][y-1] != UNABLE_INT:
						return
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x+2][y-1] = current_brick_tile_type
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x+1][y-1] = UNABLE_INT
		BrickShape.SHAPE_T:
			##            1      1      1
			## 1 0 1 => 1 0 => 1 0 1 => 0 1
			##   1        1             1
			if current_brick_direction == Vector2i.UP:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x+1][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT:
						return
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
			elif current_brick_direction == Vector2i.RIGHT:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x-1][y-1] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 1 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+1][y] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+1][y] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
			elif current_brick_direction == Vector2i.DOWN:
				if move_direction == Vector2i.LEFT:
					if x <= 1 or \
						brick_grid[x-2][y] != UNABLE_INT or \
						brick_grid[x-1][y-1] != UNABLE_INT:
						return
					brick_grid[x-2][y] = current_brick_tile_type
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x-1][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x-1][y] = UNABLE_INT
					brick_grid[x][y-1] = UNABLE_INT
			elif current_brick_direction == Vector2i.LEFT:
				if move_direction == Vector2i.LEFT:
					if x <= 0 or \
						brick_grid[x-1][y-1] != UNABLE_INT or \
						brick_grid[x-1][y] != UNABLE_INT or \
						brick_grid[x-1][y+1] != UNABLE_INT:
						return
					brick_grid[x-1][y-1] = current_brick_tile_type
					brick_grid[x-1][y] = current_brick_tile_type
					brick_grid[x-1][y+1] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
					brick_grid[x+1][y] = UNABLE_INT
				elif move_direction == Vector2i.RIGHT:
					if x >= game_area_width - 2 or \
						brick_grid[x+1][y-1] != UNABLE_INT or \
						brick_grid[x+1][y+1] != UNABLE_INT or \
						brick_grid[x+2][y] != UNABLE_INT:
						return
					brick_grid[x+1][y-1] = current_brick_tile_type
					brick_grid[x+1][y+1] = current_brick_tile_type
					brick_grid[x+2][y] = current_brick_tile_type
					brick_grid[x][y-1] = UNABLE_INT
					brick_grid[x][y] = UNABLE_INT
					brick_grid[x][y+1] = UNABLE_INT
	# 成功移动，更新轴点
	current_brick_pivot_pos += move_direction
	# 更新砖块层图像
	update_brick_layer()

## 处理向下移动的动作（立即向下移动一格）
func handle_move_down_action():
	if check_is_fall_to_end() == false:
		update_brick_layer_by_fall()

## 处理向下移动到最底部的动作
func handle_move_to_end_action():
	stop_input_flag = true
	while check_is_fall_to_end() == false:
		update_brick_layer_by_fall()
		await get_tree().create_timer(0.02).timeout
	state_change_process()
	stop_input_flag = false

## 处理变换砖块的动作（轴点位置保持不变，根据轴点进行旋转）
func handle_update_action():
	var x = current_brick_pivot_pos.x
	var y = current_brick_pivot_pos.y
	match current_brick_shape_type:
		BrickShape.SHAPE_O:
			## 0 1
			## 1 1
			return
		BrickShape.SHAPE_I:
			##            1
			## 1 0 1 1 => 0
			##            1
			##            1
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.DOWN
			else:
				pass
				current_brick_direction = Vector2i.UP
		BrickShape.SHAPE_L:
			## 0 1 1    1 0        1    1
			## 1     =>   1 => 1 1 0 => 1
			##            1             0 1
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.RIGHT
			elif current_brick_direction == Vector2i.RIGHT:
				pass
				current_brick_direction = Vector2i.DOWN
			elif current_brick_direction == Vector2i.DOWN:
				pass
				current_brick_direction = Vector2i.LEFT
			elif current_brick_direction == Vector2i.LEFT:
				pass
				current_brick_direction = Vector2i.UP
		BrickShape.SHAPE_J:
			## 1 1 0      1    1        0 1
			##     1 =>   1 => 0 1 1 => 1
			##          1 0             1
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.RIGHT
			elif current_brick_direction == Vector2i.RIGHT:
				pass
				current_brick_direction = Vector2i.DOWN
			elif current_brick_direction == Vector2i.DOWN:
				pass
				current_brick_direction = Vector2i.LEFT
			elif current_brick_direction == Vector2i.LEFT:
				pass
				current_brick_direction = Vector2i.UP
		BrickShape.SHAPE_S:
			##   1 1    1      
			## 1 0   => 0 1
			##            1  
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.DOWN
			else:
				pass
				current_brick_direction = Vector2i.UP
		BrickShape.SHAPE_Z:
			## 1 1        1    
			##   0 1 => 0 1
			##          1  
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.DOWN
			else: 
				pass
				current_brick_direction = Vector2i.UP
		BrickShape.SHAPE_T:
			##            1      1      1
			## 1 0 1 => 1 0 => 1 0 1 => 0 1
			##   1        1             1
			if current_brick_direction == Vector2i.UP:
				pass
				current_brick_direction = Vector2i.RIGHT
			elif current_brick_direction == Vector2i.RIGHT:
				pass
				current_brick_direction = Vector2i.DOWN
			elif current_brick_direction == Vector2i.DOWN:
				pass
				current_brick_direction = Vector2i.LEFT
			elif current_brick_direction == Vector2i.LEFT:
				pass
				current_brick_direction = Vector2i.UP
	# 成功移动，更新轴点
	#current_brick_pivot_pos += move_direction
	# 更新砖块层图像
	update_brick_layer()

## 游戏状态变换过程
func state_change_process():
	print("current_game_state: " + str(current_game_state))
	match current_game_state:
		GameState.IDLE:
			pass
		GameState.SPAWN:
			spawn_fallen_brick(next_brick_shape_type, next_brick_tile_type)
			spawn_next_brick()
			update_brick_layer()
			current_game_state = GameState.FALL
		GameState.FALL:
			if check_is_fall_to_end():
				if check_is_clear_avail():
					current_game_state = GameState.CLEAR
				else:
					current_game_state = GameState.SPAWN
			else:
				update_brick_layer_by_fall()
		GameState.CLEAR:
			if check_is_clear_avail():
				clear_brick_line_from_bottom()
			else:
				current_game_state = GameState.SPAWN
				

## 测试清除行
func test_clear_line():
	for x in range(game_area_width):
		for y in range(game_area_height):
			brick_grid[x][y] = randi() % brick_tile_arr.size()
	current_game_state = GameState.CLEAR

## 开始游戏
func start_game():
	init_brick_grid()
	brick_layer.clear()
	next_brick_layer.clear()
	spawn_next_brick()
	current_game_state = GameState.SPAWN
	#test_clear_line()

## 游戏初始化
func _ready() -> void:
	brick_layer = $BrickBasePosition/BrickLayer
	next_brick_layer = $NextBrickBasePosition/NextBrickLayer
	current_game_state = GameState.IDLE
	start_game()

## 接收input按键事件
func _input(event: InputEvent) -> void:
	if stop_input_flag == true or current_game_state != GameState.FALL:
		return
	if event.is_action_pressed("move_left"):
		handle_move_left_or_right_action(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		handle_move_left_or_right_action(Vector2i.RIGHT)
	elif event.is_action_pressed("move_down"):
		handle_move_down_action()
	elif event.is_action_pressed("update"):
		handle_update_action()
	elif event.is_action_pressed("move_to_end"):
		handle_move_to_end_action()

## 定时器回调函数，用于触发游戏状态变更，更新画面
func _on_update_timer_timeout() -> void:
	state_change_process()
