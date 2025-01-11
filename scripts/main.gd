extends Node3D

const CUBE_AXIS_AMOUNT:int = 10
const Y_OFFSET:float = 10.0
const CUBE_SIZE:float = 0.9
const CUBE_BOUNCINESS:float = 0.3

var bouncy_material:PhysicsMaterial
var color_material:StandardMaterial3D

func _ready():
	bouncy_material = create_physics_material(CUBE_BOUNCINESS)
	color_material = create_color_material(Color.LIGHT_SKY_BLUE)
	spawn_cubes(CUBE_AXIS_AMOUNT, bouncy_material)

func _process(delta: float) -> void:
	#print("fps: ", Engine.get_frames_per_second())
	pass

func spawn_cubes(axis_amount:int, physics_material:PhysicsMaterial):
	for i in axis_amount:
		for j in axis_amount:
			for k in axis_amount:
				var cube = RigidBody3D.new()
				add_child(cube);
				var cube_collider = CollisionShape3D.new()
				cube_collider.shape = BoxShape3D.new()
				cube_collider.shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
				cube.add_child(cube_collider)
				var cube_mesh = MeshInstance3D.new()
				cube_mesh.mesh = BoxMesh.new()
				cube_mesh.mesh.size = cube_collider.shape.size
				cube.add_child(cube_mesh)
				cube.physics_material_override = physics_material
				cube_mesh.material_override = color_material
				cube.mass = 10.0
				cube.global_transform.origin = Vector3(i + CUBE_SIZE/2.0 - axis_amount/2.0, j + Y_OFFSET, k)

func create_physics_material(bounciness:float):
	var mat = PhysicsMaterial.new()
	mat.bounce = bounciness
	return mat

func create_color_material(color:Color):
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic_specular = 0.75
	mat.metallic = 0.1
	return mat
