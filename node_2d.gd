extends Node2D 

@export var COLS = 10
@export var ROWS = 20
@onready var CELL = get_viewport_rect().size.x / COLS

const EMPTY = 0
const FILLED = 1

const PIECES = {
	"I": [[0,0],[1,0],[2,0],[3,0]],      # 横棒
	"O": [[0,0],[1,0],[0,1],[1,1]],      # 四角
	"T": [[0,0],[1,0],[2,0],[1,1]],      # T字
	"S": [[1,0],[2,0],[0,1],[1,1]],      # S字
	"Z": [[0,0],[1,0],[1,1],[2,1]],      # Z字
	"J": [[0,0],[0,1],[1,1],[2,1]],      # J字
	"L": [[2,0],[0,1],[1,1],[2,1]],      # L字
}

var grid = []
var current_piece = []        # 落下中ピースの絶対座標を持つ（案A）
var piece_pos = Vector2(4, 0)
var is_game_over = false
var retry_button

func spawn_piece():
	var keys = PIECES.keys()
	var name = keys[randi() % keys.size()]
	current_piece = PIECES[name]
	piece_pos = Vector2(4, 0)
	
	if not _is_valid(current_piece, piece_pos):
		game_over()

func game_over():
	is_game_over = true
	
	var btn = Button.new()
	btn.text = "RETRY"
	btn.position = Vector2(250, 650)   # 画面中央あたり
	btn.pressed.connect(_on_retry)
	add_child(btn)
	retry_button = btn                 # 後で消すため覚えておく

func _on_retry():
	retry_button.queue_free()
	reset_game()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for y in range(ROWS):
		var row = []
		for x in range(COLS):
			row.append(EMPTY)
		grid.append(row)

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_on_fall)
	add_child(timer)
	timer.start()

	spawn_piece()

func _on_fall():
	if is_game_over:
		return
	
	var next_pos = piece_pos + Vector2(0, 1)
	if _is_valid(current_piece, next_pos):
		piece_pos = next_pos
	else:
		lock_piece()
		clear_lines()
	
	queue_redraw()

func _is_valid(piece, pos) -> bool:
	for cell in piece:
		var x = int(pos.x + cell[0])
		var y = int(pos.y + cell[1])
		
		if (x < 0 or x >= COLS or y >= ROWS):
			return false
		
		if grid[y][x] != EMPTY:
			return false
	
	return true

func _input(event):
	if is_game_over:
		return
	
	if (event.is_action_pressed("ui_left")):
		try_move(Vector2(-1, 0))
	elif event.is_action_pressed("ui_right"):
		try_move(Vector2(1, 0))
	elif event.is_action_pressed("ui_down"):
		try_move(Vector2(0, 1))
	elif event.is_action_pressed("ui_up"):
		try_rotate()

func try_move(offset):
	var next_pos = piece_pos + offset
	if _is_valid(current_piece, next_pos):
		piece_pos = next_pos
		queue_redraw()

func try_rotate():
	var pivot = Vector2(1, 1)        # 回転の中心（仮に(1,1)）
	var rotated = []
	for cell in current_piece:
		# ① 中心を引いて、原点基準にする
		var rx = cell[0] - pivot.x
		var ry = cell[1] - pivot.y
		# ② 90度回す
		var nx = -ry
		var ny = rx
		# ③ 中心を足して戻す
		rotated.append([nx + pivot.x, ny + pivot.y])
	
	if _is_valid(rotated, piece_pos):
		current_piece = rotated
		queue_redraw()

func lock_piece():
	for cell in current_piece:
		var x = int(piece_pos.x + cell[0])
		var y = int(piece_pos.y + cell[1])
		grid[y][x] = FILLED
	spawn_piece()

func clear_lines():
	for y in range(ROWS):
		if not grid[y].has(EMPTY):
			grid.remove_at(y)
			grid.insert(0, make_empty_row())

func make_empty_row():
	var row = []
	for x in range(COLS):
		row.append(EMPTY)
	return row
			

func _draw() -> void:
	for y in range(ROWS):
		for x in range(COLS):
			if grid[y][x] != EMPTY:
				# その位置に四角を描く
				var pos = Vector2(x * CELL, y * CELL)
				var size = Vector2(CELL - 1, CELL - 1)   # -1で隙間=マス目に見える
				draw_rect(Rect2(pos, size), Color(0.3, 0.7, 1.0))
				
	for cell in current_piece:
		var x = piece_pos.x + cell[0]
		var y = piece_pos.y + cell[1]
		var pos = Vector2(x * CELL, y * CELL)
		draw_rect(Rect2(pos, Vector2(CELL-1, CELL-1)), Color(0.8, 0.4, 1.0))
	
	if is_game_over:
		show_game_over()

func reset_game():
	grid = []
	for y in range(ROWS):
		var row = []
		for x in range(COLS):
			row.append(EMPTY)
		grid.append(row)
	
	is_game_over = false
	spawn_piece()
	queue_redraw()

func show_game_over():
	var font = ThemeDB.fallback_font
	var font_size = 48
	var text = "GAME OVER"
	
	# 文字列の幅を測る
	var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# 画面の中心から、文字幅の半分を引いた位置 = 中央揃え
	var screen = get_viewport_rect().size
	draw_rect(Rect2(Vector2(0,0), screen), Color(0, 0, 0, 0.5))
	var pos = Vector2((screen.x - text_width) / 2, screen.y / 2)
	
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
