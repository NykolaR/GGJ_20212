extends Spatial
class_name Ghost

var caught : float = 0.0 setget set_caught

onready var raycast : RayCast = $Cam_y/Cam_x/Camera/RayCast
onready var tween : Tween = $Tween

onready var reticle : TextureRect = $CenterContainer/Reticle
const HIT_SCALE : Vector2 = Vector2(0.25, 0.25)
const MISS_SCALE : Vector2 = Vector2(0.15, 0.15)
const FLING_SCALE : Vector2 = Vector2(0.1, 0.1)

# GLES2 == CPUParticles
onready var particles : CPUParticles = $Particles
onready var fling : TextureProgress = $Fling

onready var cam_y : Spatial = $Cam_y
onready var cam_x : Spatial = $Cam_y/Cam_x

var possessed : Possessable = null

const charge_time : float = 1.8
const transfer_time : float = 3.0
const min_transfer_time : float = 1.0

signal possess_released

func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if NetHelper.online and not is_network_master():
		# current scene tree is not controlling the ghost
		# stops processing physics func & input processing; only the person playing this ghost can control them
		set_physics_process(false)
		set_process_input(false)
		var mat : SpatialMaterial = particles.material_override
		if mat:
			mat.albedo_texture = $Viewport.get_texture()
	else:
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
			reticle.modulate.a = 1
			reticle.rect_scale = HIT_SCALE
			# only collides with possessables
			var col : Possessable = raycast.get_collider().get_parent() as Possessable # gross but is fine
			
			if col:
				if Input.is_action_just_pressed("possess"):
					# start fling bar movement
					tween.interpolate_property(fling, "value", 0.000000000001, 1, charge_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
					tween.start()
					connect("possess_released", self, "switch_target", [col], CONNECT_ONESHOT)
		else:
			reticle.modulate.a = 0.5
			reticle.rect_scale = MISS_SCALE
	else:
		rpc_unreliable("set_transform", global_transform)

func switch_target(target : Possessable) -> void:
	tween.stop_all()
	reticle.modulate.a = 0.1
	reticle.rect_scale = FLING_SCALE
	if possessed:
		possessed.possess(false)
	
	possessed = target
	#particles.emitting = true
	#if get_tree().network_peer:
	rpc("set_emitting",true)
	#rset_id(1, "emitting", true)
	
	#tween.interpolate_property(self, "translation", translation, target.translation, transfer_time - (fling.value*2), Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "translation", translation, (target.translation + target.center.translation), transfer_time - (pow(fling.value, 2)*(transfer_time-min_transfer_time)), Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
	fling.value = 0.0

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
		if possessed and not tween.is_active():
			possessed.magnitude = clamp(event.relative.length_squared() / 1000, 0, 0.2)


# camera movement of the fps object
func camera_control(vector : Vector2) -> void:
	cam_y.rotate_y(-vector.x * 0.01 * Settings.mouse_sens)#get_physics_process_delta_time())
	cam_x.rotation.x = clamp(cam_x.rotation.x + (-vector.y * 0.01 * Settings.mouse_sens), -1.3, 1.3)

func _tween_all_completed() -> void:
	if possessed:
		#particles.emitting = false
		#if get_tree().network_peer:
		#rset_id(1, "emitting", false)
		rpc("set_emitting",false)

func _tween_completed(object : Object, key : NodePath) -> void:
	if str(key) == ":translation":
		_tween_all_completed()
		tween.stop_all()

func set_caught(new : float) -> void:
	caught = new
	if caught >= 3.0:
		pass

remote func set_emitting(new: bool) -> void:
	particles.emitting = new
	print("My partciles are: " + String(new))

remote func set_transform(new : Transform) -> void:
	global_transform = new

func init_position():
	if is_network_master():
		var possessives : Array = get_tree().get_nodes_in_group("Possessive")
		var index : int = randi()%possessives.size()
		var target : Possessable = possessives[index]
		
		if target:
			translation = target.translation + target.center.translation
		rpc("set_transform", global_transform)
