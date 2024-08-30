extends Area2D

# 追杀和逃避目标的类型
enum TargetType {
	SCISSORS,
	ROCK,
	PAPER
}

# 当前角色的类型
@export var character_type : TargetType = TargetType.SCISSORS
# 目标列表
var hunt_target : Area2D = null
var hunt_lock = false
var flee_target : Area2D = null

# 探测范围
@export var detection_radius = 200000.0

# 速度
@export var hunt_speed = 100.0
@export var flee_speed = 50.0

# 角色场景资源
var scene_resource: PackedScene

# 屏幕边界
var screen_size : Vector2

func _ready():
	# 将角色加入对应的组
	match character_type:
		TargetType.SCISSORS:
			add_to_group("scissors")
		TargetType.ROCK:
			add_to_group("rock")
		TargetType.PAPER:
			add_to_group("paper")
	
	# 加载角色场景资源
	match character_type:
		TargetType.SCISSORS:
			scene_resource = load("res://node/scissors_node.tscn")
		TargetType.ROCK:
			scene_resource = load("res://node/rock_node.tscn")
		TargetType.PAPER:
			scene_resource = load("res://node/paper_node.tscn")

	# 初始化时立即扫描一次
	find_targets()
	
	screen_size = get_viewport().size
	screen_size.x = screen_size.x / 2
	screen_size.y = screen_size.y / 2
	
	connect("area_entered", self._on_area_entered)
	
func _physics_process(delta):
	find_targets()
	
	var direction = Vector2.ZERO
	
	avoid_collisions(delta)
	
	if hunt_target and is_instance_valid(hunt_target):
		move_towards(hunt_target.position, delta)
		
	if flee_target and is_instance_valid(flee_target):
		move_away_from(flee_target.position, delta)
		
func find_targets():
	var closest_hunt_distance = detection_radius
	var closest_flee_distance = detection_radius
	
	# 获取场景树中对应组的所有角色
	var hunt_group = []
	var flee_group = []

	match character_type:
		TargetType.SCISSORS:
			hunt_group = get_tree().get_nodes_in_group("paper")
			flee_group = get_tree().get_nodes_in_group("rock")
		TargetType.ROCK:
			hunt_group = get_tree().get_nodes_in_group("scissors")
			flee_group = get_tree().get_nodes_in_group("paper")
		TargetType.PAPER:
			hunt_group = get_tree().get_nodes_in_group("rock")
			flee_group = get_tree().get_nodes_in_group("scissors")
	
	# 寻找最近的追杀目标
	for character in hunt_group:
		if character != self:
			var distance = position.distance_to(character.position)
			if distance < closest_hunt_distance:
				hunt_target = character
				closest_hunt_distance = distance
	
	# 寻找最近的逃避目标
	for character in flee_group:
		if character != self:
			var distance = position.distance_to(character.position)
			if distance < closest_flee_distance:
				flee_target = character
				closest_flee_distance = distance

func move_towards(target_position: Vector2, delta: float):
	var direction = (target_position - position).normalized()
	position += direction * hunt_speed * delta
	
	if position.x > screen_size.x - 25:
		position.x = screen_size.x - 25
	elif position.x < -screen_size.x + 25:
		position.x = -screen_size.x + 25
	if position.y > screen_size.y- 25:
		position.y = screen_size.y - 25
	elif position.y < -screen_size.y + 25:
		position.y = -screen_size.y + 25

func move_away_from(target_position: Vector2, delta: float):
	var direction = (position - target_position).normalized()
	position += direction * flee_speed * delta
	
	if position.x > screen_size.x - 25:
		position.x = screen_size.x - 25
	elif position.x < -screen_size.x + 25:
		position.x = -screen_size.x + 25
	if position.y > screen_size.y- 25:
		position.y = screen_size.y - 25
	elif position.y < -screen_size.y + 25:
		position.y = -screen_size.y + 25

func avoid_collisions(delta: float):
	# 避免与相同类型的角色碰撞
	for character in get_tree().get_nodes_in_group(character_type_to_group()):
		if character != self:
			var distance = position.distance_to(character.position)
			if distance < 25.0:
				var direction = (position - character.position).normalized()
				position += direction * flee_speed * delta

func character_type_to_group() -> String:
	match character_type:
		TargetType.SCISSORS:
			return "scissors"
		TargetType.ROCK:
			return "rock"
		TargetType.PAPER:
			return "paper"
	return ""

func _on_area_entered(body):
	# 碰撞到追杀目标
	if body == hunt_target and not hunt_lock:
		hunt_lock = true
		
		# 删除目标
		hunt_target = null
		body.remove_from_group("scissors")
		body.remove_from_group("rock")
		body.remove_from_group("paper")
		body.queue_free()
		
		# 在目标位置生成一个相同类型的角色
		var new_instance = scene_resource.instantiate() as Area2D
		new_instance.position = body.position
		get_parent().add_child(new_instance)
		
		hunt_lock = false
