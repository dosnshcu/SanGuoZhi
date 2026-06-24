extends Marker3D

@onready var spring_arm: SpringArm3D = $SpringArm3D

@export var move_speed: float = 100.0       # 键盘平移速度
@export var rotate_speed: float = 2.0      # Q/E 旋转速度
@export var zoom_speed: float = 5.0        # 滚轮缩放速度

@export var min_zoom: float = 15.0         # 最小缩放距离
@export var max_zoom: float = 100.0        # 最大缩放距离

# --- 鼠标边缘滚动参数（已升级为长方形判定） ---
@export var edge_margin_x: float = 50.0    # 左右边缘的触发宽度（单位：像素）
@export var edge_margin_y: float = 30.0    # 上下边缘的触发高度（单位：像素）由于屏幕矮，这里设小一点手感更好
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
	# 2. 鼠标屏幕边缘滚动驱动判定 (已升级：长方形判定)
	# ====================================================
	# 只有当键盘没有按下时，才触发鼠标边缘滚动，防止冲突
	if input_dir == Vector2.ZERO:
		# 获取当前游戏窗口的实时鼠标屏幕坐标 (X, Y)
		var mouse_pos := get_viewport().get_mouse_position()
		# 获取当前游戏窗口的实际总大小 (宽, 高)
		var window_size := get_viewport().get_visible_rect().size
		
		# 【左右边缘】使用 edge_margin_x 判定
		if mouse_pos.x < edge_margin_x and mouse_pos.x >= 0:
			input_dir.x = -1.0
		elif mouse_pos.x > (window_size.x - edge_margin_x) and mouse_pos.x <= window_size.x:
			input_dir.x = 1.0
			
		# 【上下边缘】使用 edge_margin_y 判定
		if mouse_pos.y < edge_margin_y and mouse_pos.y >= 0:
			input_dir.y = -1.0
		elif mouse_pos.y > (window_size.y - edge_margin_y) and mouse_pos.y <= window_size.y:
			input_dir.y = 1.0

# ====================================================
	# 3. 物理位移执行 (应用 3D 旋转校正)
	# ====================================================
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		
		# 根据当前相机的旋转朝向，计算出绝对的“前后左右”地面向量
		var forward := Vector3(transform.basis.z.x, 0.0, transform.basis.z.z).normalized()
		var right := Vector3(transform.basis.x.x, 0.0, transform.basis.x.z).normalized()
		
		# 【修复核心】：显式声明 current_speed 的类型为 float，解除编译器的类型推导危机
		var current_speed: float = edge_move_speed
		
		# 判断是否有键盘按键按下，如果有，则切换为键盘速度
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
			current_speed = move_speed
		
		# 此时类型绝对明确，`:=` 可以完美推导
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
	# 新增：按下 F11 键切换全屏/窗口化
	# ====================================================
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# ====================================================
	# 5. 鼠标滚轮缩放大地图
	# ====================================================
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_speed, min_zoom, max_zoom)
