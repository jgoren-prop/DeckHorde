extends Control
class_name Weapon3DDisplay
## Weapon3DDisplay - Displays a 3D weapon model with targeting and firing animations
## Uses SubViewport for 3D rendering within 2D UI

signal weapon_ready()
signal fire_started()
signal fire_completed()

# SubViewport for 3D rendering
var _sub_viewport: SubViewport = null
var _sub_viewport_container: SubViewportContainer = null

# 3D scene components
var _camera: Camera3D = null
var _weapon_model: Node3D = null
var _muzzle_point: Node3D = null  # Where projectiles originate
var _light: DirectionalLight3D = null

# Weapon info
var _card_id: String = ""
var _card_name: String = ""
var _damage_type: String = "kinetic"

# Animation state
var _target_position: Vector2 = Vector2.ZERO
var _is_firing: bool = false

# Muzzle flash
var _muzzle_flash: OmniLight3D = null
var _muzzle_flash_mesh: MeshInstance3D = null

# Weapon type to 3D model mapping
const WEAPON_MODELS: Dictionary = {
	# Kinetic weapons - guns
	"pistol": "pistol",
	"heavy_pistol": "pistol",
	"shotgun": "shotgun",
	"assault_rifle": "rifle",
	"sniper_rifle": "rifle",
	"burst_fire": "pistol",
	"chain_gun": "minigun",
	"double_tap": "pistol",
	"marksman": "rifle",
	"railgun": "railgun",
	# Thermal weapons - explosives/fire
	"frag_grenade": "grenade",
	"rocket": "launcher",
	"incendiary": "flamethrower",
	"firebomb": "grenade",
	"cluster_bomb": "launcher",
	"inferno": "flamethrower",
	"napalm_strike": "launcher",
	# Arcane weapons - magical
	"hex_bolt": "wand",
	"curse_wave": "staff",
	"soul_drain": "orb",
	"hex_detonation": "wand",
	"life_siphon": "orb",
	"dark_ritual": "staff",
	"spreading_plague": "staff",
	# Fortress weapons - defensive
	"shield_bash": "shield",
	"iron_volley": "shield",
	"bulwark_shot": "shield",
	"fortified_barrage": "cannon",
	"reactive_shell": "shield",
	"siege_cannon": "cannon",
	# Shadow weapons - precision
	"assassins_strike": "dagger",
	"shadow_bolt": "crossbow",
	"precision_shot": "rifle",
	"backstab": "dagger",
	"killing_blow": "dagger",
	"shadow_barrage": "crossbow",
	# Utility weapons
	"quick_shot": "pistol",
	"flurry": "pistol",
	"chain_strike": "pistol",
	"momentum": "pistol",
	"rapid_fire": "minigun",
	"overdrive": "pistol",
	# Control weapons
	"repulsor": "gauntlet",
	"barrier_shot": "gauntlet",
	"lockdown": "cannon",
	"far_strike": "crossbow",
	"killzone": "cannon",
	"perimeter": "gauntlet",
	# Volatile weapons
	"overcharge": "pistol",
	"reckless_blast": "launcher",
	"blood_rocket": "launcher",
	"unstable_core": "orb",
	"kamikaze_swarm": "launcher",
	"desperation": "pistol",
}

# Model colors by damage type
const TYPE_COLORS: Dictionary = {
	"kinetic": Color(0.6, 0.6, 0.7),
	"thermal": Color(0.8, 0.4, 0.2),
	"arcane": Color(0.6, 0.3, 0.8),
	"none": Color(0.5, 0.5, 0.5)
}

# Muzzle flash colors
const MUZZLE_COLORS: Dictionary = {
	"kinetic": Color(1.0, 0.9, 0.6),
	"thermal": Color(1.0, 0.5, 0.2),
	"arcane": Color(0.8, 0.4, 1.0),
	"none": Color(1.0, 1.0, 1.0)
}


func _ready() -> void:
	_setup_3d_viewport()


func _setup_3d_viewport() -> void:
	"""Setup the SubViewport for 3D rendering."""
	# Create SubViewportContainer
	_sub_viewport_container = SubViewportContainer.new()
	_sub_viewport_container.name = "ViewportContainer"
	_sub_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_viewport_container.stretch = true
	add_child(_sub_viewport_container)
	
	# Create SubViewport
	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "SubViewport"
	_sub_viewport.size = Vector2i(256, 256)
	_sub_viewport.transparent_bg = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport_container.add_child(_sub_viewport)
	
	# Create camera
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.position = Vector3(0, 0.5, 2.5)
	# Use look_at_from_position since node isn't in tree yet
	_camera.look_at_from_position(_camera.position, Vector3.ZERO, Vector3.UP)
	_camera.fov = 45.0
	_sub_viewport.add_child(_camera)
	
	# Create lighting
	_light = DirectionalLight3D.new()
	_light.name = "Light"
	_light.position = Vector3(2, 3, 2)
	# Use look_at_from_position since node isn't in tree yet
	_light.look_at_from_position(_light.position, Vector3.ZERO, Vector3.UP)
	_light.light_energy = 1.2
	_sub_viewport.add_child(_light)
	
	# Add ambient light
	var world_env: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.35)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	_sub_viewport.add_child(world_env)


func setup(card_def) -> void:
	"""Setup the 3D weapon for a card definition."""
	if not card_def:
		return
	
	_card_id = card_def.card_id
	_card_name = card_def.card_name
	_damage_type = card_def.damage_type
	
	# Create the 3D weapon model
	_create_weapon_model()
	
	weapon_ready.emit()


func _create_weapon_model() -> void:
	"""Create a 3D weapon model based on the card type."""
	# Clean up existing model
	if _weapon_model and is_instance_valid(_weapon_model):
		_weapon_model.queue_free()
	
	# Create root node for weapon
	_weapon_model = Node3D.new()
	_weapon_model.name = "WeaponModel"
	_sub_viewport.add_child(_weapon_model)
	
	# Determine weapon type
	var weapon_type: String = WEAPON_MODELS.get(_card_id, "pistol")
	var color: Color = TYPE_COLORS.get(_damage_type, TYPE_COLORS["none"])
	
	# Create weapon mesh based on type
	match weapon_type:
		"pistol":
			_create_pistol_mesh(color)
		"rifle":
			_create_rifle_mesh(color)
		"shotgun":
			_create_shotgun_mesh(color)
		"minigun":
			_create_minigun_mesh(color)
		"launcher":
			_create_launcher_mesh(color)
		"grenade":
			_create_grenade_mesh(color)
		"flamethrower":
			_create_flamethrower_mesh(color)
		"wand":
			_create_wand_mesh(color)
		"staff":
			_create_staff_mesh(color)
		"orb":
			_create_orb_mesh(color)
		"shield":
			_create_shield_mesh(color)
		"cannon":
			_create_cannon_mesh(color)
		"dagger":
			_create_dagger_mesh(color)
		"crossbow":
			_create_crossbow_mesh(color)
		"gauntlet":
			_create_gauntlet_mesh(color)
		"railgun":
			_create_railgun_mesh(color)
		_:
			_create_pistol_mesh(color)
	
	# Setup muzzle flash (hidden initially)
	_setup_muzzle_flash()


func _create_material(color: Color, metallic: float = 0.5, roughness: float = 0.4) -> StandardMaterial3D:
	"""Create a standard material with given properties."""
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _create_pistol_mesh(color: Color) -> void:
	"""Create a pistol-shaped mesh."""
	# Main body (box)
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.15, 0.25, 0.6)
	body.material_override = _create_material(color)
	body.position = Vector3(0, 0, 0)
	_weapon_model.add_child(body)
	
	# Barrel (cylinder)
	var barrel := MeshInstance3D.new()
	barrel.mesh = CylinderMesh.new()
	barrel.mesh.top_radius = 0.04
	barrel.mesh.bottom_radius = 0.04
	barrel.mesh.height = 0.4
	barrel.material_override = _create_material(color.darkened(0.2), 0.7, 0.3)
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0.08, 0.45)
	_weapon_model.add_child(barrel)
	
	# Grip (box)
	var grip := MeshInstance3D.new()
	grip.mesh = BoxMesh.new()
	grip.mesh.size = Vector3(0.12, 0.35, 0.15)
	grip.material_override = _create_material(color.darkened(0.3), 0.3, 0.6)
	grip.position = Vector3(0, -0.25, -0.15)
	grip.rotation_degrees.x = -15
	_weapon_model.add_child(grip)
	
	# Set muzzle point
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0.08, 0.65)
	_weapon_model.add_child(_muzzle_point)


func _create_rifle_mesh(color: Color) -> void:
	"""Create a rifle-shaped mesh."""
	# Long body
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.12, 0.18, 1.0)
	body.material_override = _create_material(color)
	body.position = Vector3(0, 0, 0)
	_weapon_model.add_child(body)
	
	# Barrel
	var barrel := MeshInstance3D.new()
	barrel.mesh = CylinderMesh.new()
	barrel.mesh.top_radius = 0.025
	barrel.mesh.bottom_radius = 0.025
	barrel.mesh.height = 0.5
	barrel.material_override = _create_material(color.darkened(0.2), 0.8, 0.2)
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0.03, 0.7)
	_weapon_model.add_child(barrel)
	
	# Stock
	var stock := MeshInstance3D.new()
	stock.mesh = BoxMesh.new()
	stock.mesh.size = Vector3(0.1, 0.2, 0.4)
	stock.material_override = _create_material(color.darkened(0.4), 0.2, 0.7)
	stock.position = Vector3(0, 0, -0.6)
	_weapon_model.add_child(stock)
	
	# Scope
	var scope := MeshInstance3D.new()
	scope.mesh = CylinderMesh.new()
	scope.mesh.top_radius = 0.03
	scope.mesh.bottom_radius = 0.03
	scope.mesh.height = 0.2
	scope.material_override = _create_material(Color(0.1, 0.1, 0.12), 0.6, 0.3)
	scope.rotation_degrees.x = 90
	scope.position = Vector3(0, 0.12, 0.1)
	_weapon_model.add_child(scope)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0.03, 0.95)
	_weapon_model.add_child(_muzzle_point)


func _create_shotgun_mesh(color: Color) -> void:
	"""Create a shotgun-shaped mesh."""
	# Double barrel
	for i in [-1, 1]:
		var barrel := MeshInstance3D.new()
		barrel.mesh = CylinderMesh.new()
		barrel.mesh.top_radius = 0.045
		barrel.mesh.bottom_radius = 0.05
		barrel.mesh.height = 0.8
		barrel.material_override = _create_material(color.darkened(0.1), 0.7, 0.3)
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(i * 0.055, 0, 0.3)
		_weapon_model.add_child(barrel)
	
	# Body
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.18, 0.15, 0.5)
	body.material_override = _create_material(color)
	body.position = Vector3(0, -0.08, -0.15)
	_weapon_model.add_child(body)
	
	# Stock
	var stock := MeshInstance3D.new()
	stock.mesh = BoxMesh.new()
	stock.mesh.size = Vector3(0.12, 0.18, 0.35)
	stock.material_override = _create_material(color.darkened(0.4), 0.2, 0.7)
	stock.position = Vector3(0, -0.05, -0.55)
	_weapon_model.add_child(stock)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.7)
	_weapon_model.add_child(_muzzle_point)


func _create_minigun_mesh(color: Color) -> void:
	"""Create a minigun-shaped mesh."""
	# Barrel cluster
	for i in range(6):
		var angle: float = i * PI / 3
		var barrel := MeshInstance3D.new()
		barrel.mesh = CylinderMesh.new()
		barrel.mesh.top_radius = 0.025
		barrel.mesh.bottom_radius = 0.025
		barrel.mesh.height = 0.6
		barrel.material_override = _create_material(color.darkened(0.2), 0.8, 0.2)
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(cos(angle) * 0.08, sin(angle) * 0.08, 0.2)
		_weapon_model.add_child(barrel)
	
	# Body
	var body := MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	body.mesh.top_radius = 0.15
	body.mesh.bottom_radius = 0.12
	body.mesh.height = 0.4
	body.material_override = _create_material(color)
	body.rotation_degrees.x = 90
	body.position = Vector3(0, 0, -0.15)
	_weapon_model.add_child(body)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.5)
	_weapon_model.add_child(_muzzle_point)


func _create_launcher_mesh(color: Color) -> void:
	"""Create a rocket launcher-shaped mesh."""
	# Main tube
	var tube := MeshInstance3D.new()
	tube.mesh = CylinderMesh.new()
	tube.mesh.top_radius = 0.1
	tube.mesh.bottom_radius = 0.1
	tube.mesh.height = 0.9
	tube.material_override = _create_material(color, 0.4, 0.5)
	tube.rotation_degrees.x = 90
	_weapon_model.add_child(tube)
	
	# Handle
	var handle := MeshInstance3D.new()
	handle.mesh = BoxMesh.new()
	handle.mesh.size = Vector3(0.08, 0.25, 0.1)
	handle.material_override = _create_material(color.darkened(0.3))
	handle.position = Vector3(0, -0.2, -0.15)
	_weapon_model.add_child(handle)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.45)
	_weapon_model.add_child(_muzzle_point)


func _create_grenade_mesh(color: Color) -> void:
	"""Create a grenade-shaped mesh."""
	var body := MeshInstance3D.new()
	body.mesh = SphereMesh.new()
	body.mesh.radius = 0.15
	body.mesh.height = 0.3
	body.material_override = _create_material(color, 0.3, 0.6)
	_weapon_model.add_child(body)
	
	# Pin
	var pin := MeshInstance3D.new()
	pin.mesh = TorusMesh.new()
	pin.mesh.inner_radius = 0.02
	pin.mesh.outer_radius = 0.05
	pin.material_override = _create_material(Color(0.7, 0.7, 0.2), 0.8, 0.2)
	pin.position = Vector3(0.15, 0.1, 0)
	_weapon_model.add_child(pin)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.2)
	_weapon_model.add_child(_muzzle_point)


func _create_flamethrower_mesh(color: Color) -> void:
	"""Create a flamethrower-shaped mesh."""
	# Tank
	var tank := MeshInstance3D.new()
	tank.mesh = CylinderMesh.new()
	tank.mesh.top_radius = 0.12
	tank.mesh.bottom_radius = 0.12
	tank.mesh.height = 0.4
	tank.material_override = _create_material(Color(0.6, 0.3, 0.1), 0.3, 0.5)
	tank.position = Vector3(0, 0, -0.3)
	_weapon_model.add_child(tank)
	
	# Nozzle
	var nozzle := MeshInstance3D.new()
	nozzle.mesh = CylinderMesh.new()
	nozzle.mesh.top_radius = 0.08
	nozzle.mesh.bottom_radius = 0.04
	nozzle.mesh.height = 0.5
	nozzle.material_override = _create_material(color, 0.6, 0.3)
	nozzle.rotation_degrees.x = 90
	nozzle.position = Vector3(0, 0, 0.2)
	_weapon_model.add_child(nozzle)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.45)
	_weapon_model.add_child(_muzzle_point)


func _create_wand_mesh(color: Color) -> void:
	"""Create a magic wand mesh."""
	# Shaft
	var shaft := MeshInstance3D.new()
	shaft.mesh = CylinderMesh.new()
	shaft.mesh.top_radius = 0.02
	shaft.mesh.bottom_radius = 0.03
	shaft.mesh.height = 0.6
	shaft.material_override = _create_material(color.darkened(0.3), 0.2, 0.6)
	shaft.rotation_degrees.x = 90
	_weapon_model.add_child(shaft)
	
	# Gem
	var gem := MeshInstance3D.new()
	gem.mesh = SphereMesh.new()
	gem.mesh.radius = 0.06
	gem.material_override = _create_material(color, 0.9, 0.1)
	gem.material_override.emission_enabled = true
	gem.material_override.emission = color
	gem.material_override.emission_energy_multiplier = 0.5
	gem.position = Vector3(0, 0, 0.35)
	_weapon_model.add_child(gem)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.42)
	_weapon_model.add_child(_muzzle_point)


func _create_staff_mesh(color: Color) -> void:
	"""Create a magic staff mesh."""
	# Shaft
	var shaft := MeshInstance3D.new()
	shaft.mesh = CylinderMesh.new()
	shaft.mesh.top_radius = 0.03
	shaft.mesh.bottom_radius = 0.04
	shaft.mesh.height = 1.2
	shaft.material_override = _create_material(color.darkened(0.4), 0.2, 0.7)
	shaft.rotation_degrees.x = 90
	_weapon_model.add_child(shaft)
	
	# Crystal top
	var crystal := MeshInstance3D.new()
	crystal.mesh = PrismMesh.new()
	crystal.mesh.size = Vector3(0.15, 0.25, 0.15)
	crystal.material_override = _create_material(color, 0.9, 0.1)
	crystal.material_override.emission_enabled = true
	crystal.material_override.emission = color
	crystal.material_override.emission_energy_multiplier = 0.8
	crystal.position = Vector3(0, 0, 0.7)
	_weapon_model.add_child(crystal)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.85)
	_weapon_model.add_child(_muzzle_point)


func _create_orb_mesh(color: Color) -> void:
	"""Create a magic orb mesh."""
	var orb := MeshInstance3D.new()
	orb.mesh = SphereMesh.new()
	orb.mesh.radius = 0.18
	orb.material_override = _create_material(color, 0.9, 0.05)
	orb.material_override.emission_enabled = true
	orb.material_override.emission = color
	orb.material_override.emission_energy_multiplier = 1.0
	_weapon_model.add_child(orb)
	
	# Inner glow
	var inner := MeshInstance3D.new()
	inner.mesh = SphereMesh.new()
	inner.mesh.radius = 0.12
	inner.material_override = _create_material(color.lightened(0.5), 1.0, 0.0)
	inner.material_override.emission_enabled = true
	inner.material_override.emission = color.lightened(0.3)
	inner.material_override.emission_energy_multiplier = 2.0
	_weapon_model.add_child(inner)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.2)
	_weapon_model.add_child(_muzzle_point)


func _create_shield_mesh(color: Color) -> void:
	"""Create a shield mesh."""
	var shield := MeshInstance3D.new()
	shield.mesh = CylinderMesh.new()
	shield.mesh.top_radius = 0.3
	shield.mesh.bottom_radius = 0.25
	shield.mesh.height = 0.08
	shield.material_override = _create_material(color, 0.7, 0.3)
	shield.rotation_degrees.x = 90
	_weapon_model.add_child(shield)
	
	# Boss (center decoration)
	var boss := MeshInstance3D.new()
	boss.mesh = SphereMesh.new()
	boss.mesh.radius = 0.08
	boss.material_override = _create_material(color.lightened(0.2), 0.8, 0.2)
	boss.position = Vector3(0, 0, 0.05)
	_weapon_model.add_child(boss)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.15)
	_weapon_model.add_child(_muzzle_point)


func _create_cannon_mesh(color: Color) -> void:
	"""Create a cannon mesh."""
	# Barrel
	var barrel := MeshInstance3D.new()
	barrel.mesh = CylinderMesh.new()
	barrel.mesh.top_radius = 0.08
	barrel.mesh.bottom_radius = 0.12
	barrel.mesh.height = 0.7
	barrel.material_override = _create_material(color, 0.7, 0.3)
	barrel.rotation_degrees.x = 90
	_weapon_model.add_child(barrel)
	
	# Base
	var base := MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.mesh.size = Vector3(0.3, 0.2, 0.3)
	base.material_override = _create_material(color.darkened(0.3), 0.5, 0.5)
	base.position = Vector3(0, -0.15, -0.25)
	_weapon_model.add_child(base)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.35)
	_weapon_model.add_child(_muzzle_point)


func _create_dagger_mesh(color: Color) -> void:
	"""Create a dagger mesh."""
	# Blade
	var blade := MeshInstance3D.new()
	blade.mesh = PrismMesh.new()
	blade.mesh.size = Vector3(0.04, 0.35, 0.08)
	blade.material_override = _create_material(Color(0.8, 0.8, 0.85), 0.9, 0.1)
	blade.rotation_degrees.x = 90
	blade.position = Vector3(0, 0, 0.2)
	_weapon_model.add_child(blade)
	
	# Guard
	var guard := MeshInstance3D.new()
	guard.mesh = BoxMesh.new()
	guard.mesh.size = Vector3(0.15, 0.03, 0.04)
	guard.material_override = _create_material(color, 0.7, 0.3)
	_weapon_model.add_child(guard)
	
	# Handle
	var handle := MeshInstance3D.new()
	handle.mesh = CylinderMesh.new()
	handle.mesh.top_radius = 0.025
	handle.mesh.bottom_radius = 0.025
	handle.mesh.height = 0.2
	handle.material_override = _create_material(color.darkened(0.3), 0.3, 0.6)
	handle.rotation_degrees.x = 90
	handle.position = Vector3(0, 0, -0.15)
	_weapon_model.add_child(handle)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.4)
	_weapon_model.add_child(_muzzle_point)


func _create_crossbow_mesh(color: Color) -> void:
	"""Create a crossbow mesh."""
	# Stock
	var stock := MeshInstance3D.new()
	stock.mesh = BoxMesh.new()
	stock.mesh.size = Vector3(0.08, 0.08, 0.5)
	stock.material_override = _create_material(color.darkened(0.3), 0.2, 0.6)
	_weapon_model.add_child(stock)
	
	# Bow arms
	for i in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.mesh = BoxMesh.new()
		arm.mesh.size = Vector3(0.3, 0.02, 0.04)
		arm.material_override = _create_material(color, 0.4, 0.4)
		arm.position = Vector3(i * 0.12, 0, 0.2)
		arm.rotation_degrees.z = i * -20
		_weapon_model.add_child(arm)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.3)
	_weapon_model.add_child(_muzzle_point)


func _create_gauntlet_mesh(color: Color) -> void:
	"""Create a gauntlet mesh."""
	# Hand
	var hand := MeshInstance3D.new()
	hand.mesh = BoxMesh.new()
	hand.mesh.size = Vector3(0.2, 0.08, 0.25)
	hand.material_override = _create_material(color, 0.7, 0.3)
	_weapon_model.add_child(hand)
	
	# Fingers
	for i in range(4):
		var finger := MeshInstance3D.new()
		finger.mesh = BoxMesh.new()
		finger.mesh.size = Vector3(0.035, 0.04, 0.12)
		finger.material_override = _create_material(color.darkened(0.1), 0.6, 0.3)
		finger.position = Vector3(-0.06 + i * 0.04, 0, 0.17)
		_weapon_model.add_child(finger)
	
	# Palm gem
	var gem := MeshInstance3D.new()
	gem.mesh = SphereMesh.new()
	gem.mesh.radius = 0.05
	gem.material_override = _create_material(color.lightened(0.3), 0.9, 0.1)
	gem.material_override.emission_enabled = true
	gem.material_override.emission = color
	gem.material_override.emission_energy_multiplier = 0.8
	gem.position = Vector3(0, 0.05, 0)
	_weapon_model.add_child(gem)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0.05, 0.15)
	_weapon_model.add_child(_muzzle_point)


func _create_railgun_mesh(color: Color) -> void:
	"""Create a railgun mesh."""
	# Main body
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.12, 0.15, 0.8)
	body.material_override = _create_material(color, 0.8, 0.2)
	_weapon_model.add_child(body)
	
	# Rails
	for i in [-1, 1]:
		var rail := MeshInstance3D.new()
		rail.mesh = BoxMesh.new()
		rail.mesh.size = Vector3(0.02, 0.08, 1.0)
		rail.material_override = _create_material(Color(0.2, 0.5, 0.8), 0.9, 0.1)
		rail.material_override.emission_enabled = true
		rail.material_override.emission = Color(0.2, 0.5, 0.9)
		rail.material_override.emission_energy_multiplier = 0.5
		rail.position = Vector3(i * 0.08, 0, 0.1)
		_weapon_model.add_child(rail)
	
	_muzzle_point = Node3D.new()
	_muzzle_point.name = "MuzzlePoint"
	_muzzle_point.position = Vector3(0, 0, 0.6)
	_weapon_model.add_child(_muzzle_point)


func _setup_muzzle_flash() -> void:
	"""Setup muzzle flash light and mesh."""
	if not _muzzle_point:
		return
	
	var flash_color: Color = MUZZLE_COLORS.get(_damage_type, Color.WHITE)
	
	# Light
	_muzzle_flash = OmniLight3D.new()
	_muzzle_flash.name = "MuzzleFlash"
	_muzzle_flash.light_color = flash_color
	_muzzle_flash.light_energy = 0.0
	_muzzle_flash.omni_range = 1.5
	_muzzle_flash.omni_attenuation = 2.0
	_muzzle_point.add_child(_muzzle_flash)
	
	# Flash mesh
	_muzzle_flash_mesh = MeshInstance3D.new()
	_muzzle_flash_mesh.mesh = SphereMesh.new()
	_muzzle_flash_mesh.mesh.radius = 0.08
	_muzzle_flash_mesh.material_override = StandardMaterial3D.new()
	_muzzle_flash_mesh.material_override.albedo_color = flash_color
	_muzzle_flash_mesh.material_override.emission_enabled = true
	_muzzle_flash_mesh.material_override.emission = flash_color
	_muzzle_flash_mesh.material_override.emission_energy_multiplier = 3.0
	_muzzle_flash_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_muzzle_flash_mesh.visible = false
	_muzzle_point.add_child(_muzzle_flash_mesh)


# =============================================================================
# ANIMATION METHODS
# =============================================================================

func set_target_direction(target_pos: Vector2) -> void:
	"""Set the direction the weapon should face."""
	_target_position = target_pos
	_update_weapon_rotation()


func _update_weapon_rotation() -> void:
	"""Update weapon rotation to face target."""
	if not _weapon_model:
		return
	
	# Calculate angle from center of viewport to target
	var center: Vector2 = size / 2.0
	var direction: Vector2 = _target_position - global_position - center
	var angle: float = atan2(direction.y, direction.x)
	
	# Apply rotation - weapon points in Z direction, so rotate around Y
	_weapon_model.rotation.y = -angle


func play_fire_animation() -> void:
	"""Play the weapon firing animation with muzzle flash."""
	if _is_firing:
		return
	
	_is_firing = true
	fire_started.emit()
	
	# Show muzzle flash
	if _muzzle_flash:
		_muzzle_flash.light_energy = 5.0
	if _muzzle_flash_mesh:
		_muzzle_flash_mesh.visible = true
		_muzzle_flash_mesh.scale = Vector3(1.5, 1.5, 1.5)
	
	# Recoil animation
	if _weapon_model:
		var original_pos: Vector3 = _weapon_model.position
		var tween: Tween = create_tween()
		tween.tween_property(_weapon_model, "position:z", original_pos.z - 0.1, 0.05)
		tween.tween_property(_weapon_model, "position:z", original_pos.z, 0.15)
	
	# Fade out muzzle flash
	await get_tree().create_timer(0.08).timeout
	
	if _muzzle_flash:
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(_muzzle_flash, "light_energy", 0.0, 0.15)
	
	if _muzzle_flash_mesh:
		var mesh_tween: Tween = create_tween()
		mesh_tween.set_parallel(true)
		mesh_tween.tween_property(_muzzle_flash_mesh, "scale", Vector3(0.1, 0.1, 0.1), 0.15)
		await mesh_tween.finished
		_muzzle_flash_mesh.visible = false
		_muzzle_flash_mesh.scale = Vector3.ONE
	
	_is_firing = false
	fire_completed.emit()


func get_muzzle_global_position() -> Vector2:
	"""Get the global 2D position of the muzzle point."""
	if not _muzzle_point or not _camera:
		return global_position + size / 2.0
	
	# Project 3D muzzle position to 2D viewport
	var muzzle_3d: Vector3 = _muzzle_point.global_position
	var projected: Vector2 = _camera.unproject_position(muzzle_3d)
	
	# Scale to our control size
	var viewport_size: Vector2 = Vector2(_sub_viewport.size)
	var scale_factor: Vector2 = size / viewport_size
	var local_pos: Vector2 = projected * scale_factor
	
	return global_position + local_pos


func play_idle_animation() -> void:
	"""Play subtle idle animation."""
	if not _weapon_model:
		return
	
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(_weapon_model, "rotation:x", 0.02, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_weapon_model, "rotation:x", -0.02, 1.0).set_ease(Tween.EASE_IN_OUT)


func stop_idle_animation() -> void:
	"""Stop idle animation."""
	if _weapon_model:
		_weapon_model.rotation.x = 0.0

