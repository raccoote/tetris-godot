extends TileMapLayer

var fall_timer = 0.0
var fall_delay = 0.5
var move_repeat_timer = 0
var move_repeat_delay = 0.1
var das_timer := 0.0
var arr_timer := 0.0
var das_delay := 0.2  # Delay before repeating
var arr_delay := 0.05  # Time between repeats
var soft_fall_timer := 0.0
var soft_fall_delay := 0.02
var move_direction := 0 

const ROWS = 22
const COLUMNS = 10

const TETROMINO_COLORS := {
	"I": Vector2i(0,0),  # Cyan
	"O": Vector2i(1,1),  # Yellow
	"T": Vector2i(1,2),  # Purple
	"S": Vector2i(0,3),  # Green
	"Z": Vector2i(0,2),  # Red
	"J": Vector2i(0,1),  # Blue
	"L": Vector2i(1,0),  # Orange
}

const TETROMINOS := {
	"I": [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],  # 0°
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],  # 90°
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],  # 180°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],  # 270°
	],

	"O": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],  # All rotations identical
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	],

	"T": [
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],  # 0°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1)],  # 90°
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],  # 180°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 1)],  # 270°
	],

	"S": [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],  # 0°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],  # 90°
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],  # 180°
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],  # 270°
	],

	"Z": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],  # 0°
		[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],  # 90°
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],  # 180°
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],  # 270°
	],

	"J": [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],  # 0°
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],  # 90°
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],  # 180°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],  # 270°
	],

	"L": [
		[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],  # 0°
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],  # 90°
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],  # 180°
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],  # 270°
	],
}
var current_piece = {}

func _ready():
	randomize()
	spawn_new_piece()

func _physics_process(delta):
	fall_timer += delta
	if fall_timer >= fall_delay:
		fall_timer = 0.0
		piece_gravity()
	remove_lines()
		
func _process(delta):
	update_horizontal_input(delta)

func update_horizontal_input(delta):
	# --- Soft fall ---
	if Input.is_action_pressed("soft_fall"):
		soft_fall_timer += delta
		if soft_fall_timer >= soft_fall_delay:
			move_piece(Vector2i(0, 1))
			soft_fall_timer = 0.0
	else:
		soft_fall_timer = 0.0
	# Detect input
	if Input.is_action_just_pressed("left_move"):
		move_piece(Vector2i(-1, 0))
		move_direction = -1
		das_timer = 0.0
		arr_timer = 0.0
	elif Input.is_action_just_pressed("right_move"):
		move_piece(Vector2i(1, 0))
		move_direction = 1
		das_timer = 0.0
		arr_timer = 0.0
	elif Input.is_action_just_released("left_move") and move_direction == -1:
		move_direction = 0
	elif Input.is_action_just_released("right_move") and move_direction == 1:
		move_direction = 0

	# Hold behavior (after DAS delay)
	if move_direction != 0 and Input.is_action_pressed("left_move") or Input.is_action_pressed("right_move"):
		das_timer += delta
		if das_timer >= das_delay:
			arr_timer += delta
			if arr_timer >= arr_delay:
				move_piece(Vector2i(move_direction, 0))
				arr_timer = 0.0
	else:
		das_timer = 0.0
		arr_timer = 0.0

func _input(event):
	if event.is_action_pressed("left_rot"):
		rotate_piece(1)
	elif event.is_action_pressed("right_rot"):
		rotate_piece(-1)
	elif event.is_action_pressed("hard_fall"):
		hard_drop()
		
func piece_gravity():
	erase_piece(current_piece.name, current_piece.rotation, current_piece.position)
	if not move_piece(Vector2i(0,1)):
		# Lock the piece
		draw_piece(current_piece.name, current_piece.rotation, current_piece.position)
		spawn_new_piece()
	else:
		draw_piece(current_piece.name, current_piece.rotation, current_piece.position)
		
func move_piece(offset: Vector2i):
	if can_move(offset):
		erase_piece(current_piece.name, current_piece.rotation, current_piece.position)
		current_piece.position += offset
		draw_piece(current_piece.name, current_piece.rotation, current_piece.position)
		return true

func rotate_piece(isClockwise: int):
	if (can_rotate(isClockwise)):	
		erase_piece(current_piece.name, current_piece.rotation, current_piece.position)
		current_piece.rotation = (current_piece.rotation + isClockwise) % 4
		draw_piece(current_piece.name, current_piece.rotation, current_piece.position)

func hard_drop():
	for i in range(0, ROWS):
		move_piece(Vector2i(0,1))
	fall_timer = fall_delay

func draw_piece(piece_name: String, rotation: int, pos: Vector2i):
	var shape = TETROMINOS[piece_name][rotation]
	for tile in shape:
		set_cell(pos + tile, 0, TETROMINO_COLORS[piece_name])

func erase_piece(piece_name: String, rotation: int, pos: Vector2i):
	var shape = TETROMINOS[piece_name][rotation]
	for tile in shape:
		set_cell(pos + tile, 0)

func can_move(offset: Vector2i) -> bool:
	var shape = TETROMINOS[current_piece.name][current_piece.rotation]
	for tile in shape:
		var new_pos = current_piece.position + tile + offset
		if is_occupied(new_pos):
			return false
	return true

func can_rotate(isClockwise: int) -> bool:
	var new_rotation = (current_piece.rotation + isClockwise) % 4
	var shape = TETROMINOS[current_piece.name][new_rotation]
	for tile in shape:
		var new_pos = current_piece.position + tile  # Get the absolute position of the rotated tile
		if is_occupied(new_pos):
			return false
	return true
	
func is_occupied(this_tile: Vector2i) -> bool:
	var shape = TETROMINOS[current_piece.name][current_piece.rotation]
	for tile in shape:
		if current_piece.position + tile == this_tile:
			return false  # It's part of the current piece
	return get_cell_source_id(this_tile) != -1

func remove_lines():
	for i in ROWS:
		for j in COLUMNS:
			if (get_cell_source_id(Vector2i(i,j)) == -1):
				continue
			
			

func spawn_new_piece():
	var shape_names = TETROMINO_COLORS.keys()
	current_piece = {
		"name": shape_names[randi() % shape_names.size()],
		"rotation": 0,
		"position": Vector2i(4, 0)  # start at top middle
	}	
