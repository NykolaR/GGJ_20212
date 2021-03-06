extends Spatial
class_name Ghost

var game_ended : bool = false

var caught : float = 0.0 setget set_caught
var wiggle_index : int = 0
var mouse_speed : float = 0

const wiggle : ShaderMaterial = preload("res://Assets/Visual/Shaders/PossessableMaterial.tres")

onready var raycast : RayCast = $Cam_y/Cam_x/Camera/RayCast
onready var tween : Tween = $Tween
onready var timer : Timer = $Timer

onready var reticle : TextureRect = $CenterContainer/Reticle
const HIT_SCALE : Vector2 = Vector2(0.25, 0.25)
const MISS_SCALE : Vector2 = Vector2(0.15, 0.15)
const FLING_SCALE : Vector2 = Vector2(0.1, 0.1)

# GLES2 == CPUParticles
onready var particles : CPUParticles = $Particles
onready var fling : TextureProgress = $Fling

onready var cam_y : Spatial = $Cam_y
onready var cam_x : Spatial = $Cam_y/Cam_x

var possessed : bool = false

onready var sfx : AudioStreamPlayer3D = $AudioStreamPlayer3D

var startingIdx : int
var goalIdx : int = -1
var goalObject : Possessable
var currentPossessed : Possessable

var playerHasWon = false

const charge_time : float = 1.8
const transfer_time : float = 3.0
const min_transfer_time : float = 1.0

signal possess_released

var player : KinematicBody

func _ready() -> void:
	if not player:
		player = get_tree().get_nodes_in_group("Player")[0]
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if NetHelper.online and not is_network_master():
		$Cam_y/Cam_x/Camera.current = false
		# current scene tree is not controlling the ghost
		# stops processing physics func & input processing; only the person playing this ghost can control them
		set_physics_process(false)
		set_process_input(false)
		fling.visible = false
		reticle.visible = false
		$Viewport/AnimatedSprite.playing = true
		$Viewport.render_target_update_mode = Viewport.UPDATE_WHEN_VISIBLE
		particles.visible = true
		var mat : SpatialMaterial = particles.material_override
		if mat:
			mat.albedo_texture = $Viewport.get_texture()
	else:
		set_physics_process(true)
		set_process_input(true)
		# current scene tree is controlling this ghost
		fling.visible = true
		reticle.visible = true
		$Viewport/AnimatedSprite.playing = false
		$Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		particles.visible = false
		$Cam_y/Cam_x/Camera.current = true

func _physics_process(delta: float) -> void:
	caught -= delta
	caught = max(caught, 0)
	if not tween.is_active():
		if raycast.is_colliding():
			var col : Possessable = raycast.get_collider().get_parent() as Possessable # gross but is fine
			
			if col:
				reticle.modulate.a = 1
				reticle.rect_scale = HIT_SCALE
				if Input.is_action_just_pressed("possess"):
					# start fling bar movement
					tween.interpolate_property(fling, "value", 0.000000000001, 1, charge_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
					tween.start()
					connect("possess_released", self, "switch_target", [col], CONNECT_ONESHOT)
			else:
				reticle.modulate.a = 0.5
				reticle.rect_scale = MISS_SCALE
		else:
			reticle.modulate.a = 0.5
			reticle.rect_scale = MISS_SCALE
		
		rpc_unreliable("set_wiggle", clamp(mouse_speed / 50.0, 0.15, 1.0))
	else:
		rpc_unreliable("set_transform", global_transform)
		if fling.value > 0:
			rpc_unreliable("set_wiggle", (fling.value/2.0) + 0.3)
		else:
			rpc_unreliable("set_wiggle", 0.5)

func switch_target(target : Possessable) -> void:
	tween.stop_all()
	reticle.modulate.a = 0.1
	reticle.rect_scale = FLING_SCALE
	
	possessed = true
	rpc("set_emitting",true)
	
	tween.interpolate_property(self, "translation", translation, (target.translation + target.center.translation), transfer_time - (pow(fling.value, 2)*(transfer_time-min_transfer_time)), Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
	fling.value = 0.0
	
	currentPossessed = target
	
	rpc("play_sound")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_released("possess"):
		emit_signal("possess_released")
	if fling.value > 0:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_control(event.relative)
		mouse_speed = event.relative.length_squared()
		timer.start()

# camera movement of the fps object
func camera_control(vector : Vector2) -> void:
	cam_y.rotate_y(-vector.x * 0.01 * Settings.mouse_sens)#get_physics_process_delta_time())
	cam_x.rotation.x = clamp(cam_x.rotation.x + (-vector.y * 0.01 * Settings.mouse_sens), -1.3, 1.3)

func _tween_all_completed() -> void:
	if possessed:
		rpc("set_emitting",false)
		print("possessed: " + currentPossessed.name)
		check_win()

func _tween_completed(object : Object, key : NodePath) -> void:
	if str(key) == ":translation":
		_tween_all_completed()
		tween.stop_all()

func set_caught(new : float) -> void:
	caught = new
	if caught >= 3.0:
		rpc("ghost_found")
		caught = 0
		#if not playerHasWon:
			#playerHasWon = true
			#rpc("inform_win", "Player has won")

remote func set_emitting(new: bool) -> void:
	particles.emitting = new

remote func set_transform(new : Transform) -> void:
	global_transform = new

remotesync func set_wiggle(intensity : float) -> void:
	wiggle.set_shader_param("intensity", intensity)
	wiggle.set_shader_param("time_scale", intensity)
	wiggle.set_shader_param("possess_position", global_transform.origin)

func init_position():
	if is_network_master():
		var possessives : Array = get_tree().get_nodes_in_group("Possessive")
		startingIdx = randi()%possessives.size()
		var target : Possessable = possessives[startingIdx]
		currentPossessed = target
		
		if target:
			translation = target.translation + target.center.translation
		rpc("set_transform", global_transform)
		set_wiggle(0.1)

func timer_timeout() -> void:
	mouse_speed = 0

func create_goal ():
	if is_network_master():
		var possessives : Array = get_tree().get_nodes_in_group("Possessive")
		goalIdx = randi()%possessives.size()
		while (goalIdx == startingIdx):
			goalIdx = randi()%possessives.size()
		goalObject = possessives[goalIdx]
		#goalObject.global_transform.origin.y += 1
		print("goal selected" + goalObject.name)
		print("possessed: " + currentPossessed.name)

func check_win():
	if currentPossessed == goalObject:
		rpc("ghost_win")
		#rpc("inform_win", "Ghost has won")

remotesync func ghost_found():
	init_position()

remotesync func ghost_win():
	var parent = get_parent()
	parent.remove_child(player)
	parent.remove_child(self)
	
	var old_name : String = name
	name = player.name
	set_network_master(int(name))
	
	player.name = old_name
	player.set_network_master(int(old_name))
	
	request_ready()
	player.request_ready()
	
	parent.add_child(player)
	parent.add_child(self)

remotesync func play_sound():
	sfx.play()

remotesync func inform_win (message):
	
	return
	if game_ended:
		return
	
	game_ended = true
	var game = get_tree().get_nodes_in_group("GameManager")[0]
	game.end_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
