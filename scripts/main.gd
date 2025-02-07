extends Node3D

# Physics Cubes
const CUBE_AXIS_AMOUNT: int = 10
const Y_OFFSET: float = 10.0
const CUBE_SIZE: float = 1.0
const CUBE_MASS: float = 1.0
const CUBE_BOUNCINESS: float = 0.3
const CUBE_SPREAD_FACTOR: float = 2.0

var bouncy_material: PhysicsMaterial
var color_material: StandardMaterial3D
var cube: RigidBody3D
var cube_collider: CollisionShape3D
var cube_mesh: MeshInstance3D

func _ready() -> void:
	bouncy_material = create_physics_material(CUBE_BOUNCINESS)
	color_material = create_color_material(Color.DIM_GRAY)
	spawn_cubes(CUBE_AXIS_AMOUNT, bouncy_material)

func _process(delta: float) -> void:
	# print("fps: ", Engine.get_frames_per_second())
	pass

func spawn_cubes(axis_amount: int, physics_material: PhysicsMaterial) -> void:
	for i in axis_amount:
		for j in axis_amount:
			for k in axis_amount:
				cube = RigidBody3D.new()
				# cube.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
				add_child(cube);
				cube_collider = CollisionShape3D.new()
				cube_collider.shape = BoxShape3D.new()
				cube_collider.shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
				cube.add_child(cube_collider)
				cube_mesh = MeshInstance3D.new()
				cube_mesh.mesh = BoxMesh.new()
				cube_mesh.mesh.size = cube_collider.shape.size
				cube.add_child(cube_mesh)
				cube.physics_material_override = physics_material
				cube_mesh.material_override = color_material
				cube.set_collision_layer_value(3, true)
				cube.mass = CUBE_MASS
				cube.global_transform.origin = Vector3(
					(i + CUBE_SIZE / 2.0 - axis_amount / 2.0) * CUBE_SPREAD_FACTOR,
					(j + Y_OFFSET) * CUBE_SPREAD_FACTOR,
					k * CUBE_SPREAD_FACTOR
				)
				cube.rotation_degrees = Vector3(
					randf_range(0, 360),
					randf_range(0, 360),
					randf_range(0, 360)
				)

func create_physics_material(bounciness: float) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.bounce = bounciness
	return material

func create_color_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic_specular = 0.75
	material.metallic = 0.1
	return material
