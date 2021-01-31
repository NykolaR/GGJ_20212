extends KinematicBody

var height : float = 1.8
var walk_speed : float = 3.0

const ghost_env : Environment = preload("res://Assets/Environments/Ghost.tres")

onready var environment : WorldEnvironment = $WorldEnvironment

onready var raycast : RayCast = $RayCast
onready var ghostcast : RayCast = $Cam_y/Cam_x/Camera/GhostCast

onready var cam_y : Spatial = $Cam_y
onready var cam_x : Spatial = $Cam_y/Cam_x

onready var mesh : MeshInstance = $MeshInstance

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if NetHelper.online and not is_network_master():
		# current scene tree is not in control
		set_process_input(false)
		set_physics_process(false)
		$WorldEnvironment.environment = ghost_env
	else:
		# current scene tree is in control
		mesh.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_control(event.relative)

func _physics_process(delta: float) -> void:
	movement(delta)
	
	if raycast.is_colliding():
		var ray_col : Vector3 = raycast.get_collision_point()
		global_transform.origin.y = ray_col.y + height
	
	if get_tree().network_peer:
		rpc_unreliable("set_transform_new", global_transform, $Cam_y/Cam_x/Camera/SpotLight.global_transform)
	
	if ghostcast.is_colliding():
		var ghost : Ghost = ghostcast.get_collider().get_parent() # ew
		if ghost:
			ghost.caught += delta * 2

# movement of the fps object
func movement(delta : float) -> void:
	var movement : Vector3 = Vector3()

	movement.x += Input.get_action_strength("right")
	movement.x -= Input.get_action_strength("left")

	movement.z += Input.get_action_strength("down")
	movement.z -= Input.get_action_strength("up")

	move_and_slide(movement.rotated(Vector3.UP, cam_y.rotation.y) * walk_speed)

# camera movement of the fps object
func camera_control(vector : Vector2) -> void:
	cam_y.rotate_y(-vector.x * 0.01 * Settings.mouse_sens)# * get_physics_process_delta_time())
	cam_x.rotation.x = clamp(cam_x.rotation.x + (-vector.y * 0.01 * Settings.mouse_sens), -1.3, 1.3)

remote func set_transform_new(new : Transform, flash : Transform) -> void:
	global_transform = new
	$Cam_y/Cam_x/Camera/SpotLight.global_transform = flash
