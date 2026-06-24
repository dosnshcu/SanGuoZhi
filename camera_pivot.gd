extends Marker3D

@onready var spring_arm: SpringArm3D = $SpringArm3D

@export var move_speed: float = 100.0       # 键盘平移速度
@export var rotate_speed: float = 2.0      # Q/E 旋转速度
@export var zoom_speed: float = 5.0        # 滚轮缩放速度

@export var min_zoom: float = 15.0         # 最小缩放距离
@export var max_zoom: float = 100.0        # 最大缩放距离

# --- 鼠标边缘滚动参数（全局显示器长方形判定） ---
@export var edge_margin_x: float = 50.0    # 左右边缘的触发宽度（单位：物理像素）
@export var edge_margin_y: float = 30.0    # 上下边缘的触发高度（单位：物理像素）
@export var edge_move_speed: float = 100.0 # 鼠标移到边缘时的地图滑动速度

func _process(delta: float) -> void:
	# 最终的移动方向向量（融合键盘和鼠标边缘）
	var input_dir := Vector2.ZERO
	
	# ====================================================
	# 1. 键盘驱动判定 (W/A/S/D 和 方向键)
	# ====================================================
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0

	# ====================================================
	# 2. 鼠标屏幕边缘滚动驱动判定 (硬件级全局追踪)
	# ====================================================
	if input_dir == Vector2.ZERO:
		# 【架构升级】：跨过游戏视口，直接索要鼠标在整台电脑屏幕上的绝对物理像素坐标 (0 ~ 1920...)
		var global_mouse_pos := DisplayServer.mouse_get_position()
		
		# 获取当前游戏窗口所在的那个显示器（支持多显示器）的完整物理分辨率
		var screen_id := DisplayServer.window_get_current_screen()
		var screen_size := DisplayServer.screen_get_size(screen_id)
		
		# 极其强悍的全局判定：直接用电脑屏幕的物理长方形边界作为死区
		# 【左右显示器边缘检测】
		if global_mouse_pos.x < edge_margin_x:
			input_dir.x = -1.0
		elif global_mouse_pos.x > (screen_size.x - edge_margin_x):
			input_dir.x = 1.0
			
		# 【上下显示器边缘检测】
		if global_mouse_pos.y < edge_margin_y:
			input_dir.y = -1.0
		elif global_mouse_pos.y > (screen_size.y - edge_margin_y):
			input_dir.y = 1.0

	# ====================================================
	# 3. 物理位移执行 (应用 3D 旋转校正)
	# ====================================================
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		
		var forward := Vector3(transform.basis.z.x, 0.0, transform.basis.z.z).normalized()
		var right := Vector3(transform.basis.x.x, 0.0, transform.basis.x.z).normalized()
		
		var current_speed: float = edge_move_speed
		
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
			current_speed = move_speed
		
		var move_vec := (right * input_dir.x + forward * input_dir.y) * current_speed * delta
		global_translate(move_vec)
		
	# ====================================================
	# 4. Q 和 E 键旋转地图
	# ====================================================
	if Input.is_key_pressed(KEY_Q):
		rotate_y(rotate_speed * delta)
	if Input.is_key_pressed(KEY_E):
		rotate_y(-rotate_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	# ====================================================
	# 5. 按下 F11 键切换全屏/窗口化
	# ====================================================
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# ====================================================
	# 6. 鼠标滚轮缩放大地图
	# ====================================================
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_speed, min_zoom, max_zoom)
