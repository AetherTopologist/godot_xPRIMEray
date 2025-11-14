extends Node3D
# Godot 4.x

@export var num_rays: int = 120
@export var h: float = 0.03        # integration step
@export var steps_per_frame: int = 2
@export var beta: float = 0.12     # GRIN field strength
@export var gamma: float = 0.6     # GRIN exponent

var rays := []        # array of dictionaries with pos, dir
var im := ImmediateMesh.new()
var mi := MeshInstance3D.new()

func _ready():
	# one mesh instance to draw all lines
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mi.mesh = im
	mi.material_override = mat
	add_child(mi)

	_spawn_rays()

func _spawn_rays():
	rays.clear()
	for i in range(num_rays):
		var ang = TAU * float(i) / float(num_rays)
		var dir = Vector3(cos(ang), 0.0, sin(ang)).normalized()
		rays.append({"pos": global_position, "dir": dir})
	_rebuild_lines()

func _process(_delta):
	for _i in range(steps_per_frame):
		_integrate_step()
	_rebuild_lines()

func _integrate_step():
	for r in rays:
		var p: Vector3 = r.pos
		var v: Vector3 = r.dir

		# 4th order Runge-Kutta on position with curvature acceleration from GRIN field
		var k1 = _ray_vel(p, v)
		var k2 = _ray_vel(p + 0.5*h*k1, v)
		var k3 = _ray_vel(p + 0.5*h*k2, v)
		var k4 = _ray_vel(p + h*k3, v)
		var dp = (k1 + 2.0*k2 + 2.0*k3 + k4) / 6.0

		r.pos = p + dp * h
		r.dir = (dp).normalized()

func _ray_vel(p: Vector3, dir: Vector3) -> Vector3:
	# toy GRIN: index gradient upward with radial dependence
	# replace with INSIGHT field sampling later
	var grad_n = Vector3(0.0, beta * pow(max(p.length(), 0.0001), gamma), 0.0)
	return (dir + grad_n).normalized()

func _rebuild_lines():
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var origin = global_position
	for r in rays:
		# color per-vertex (optional): white at origin, fades by distance
		im.surface_set_color(Color(1,1,1))
		im.surface_add_vertex(origin)
		im.surface_set_color(Color(0.3,0.7,1.0))
		im.surface_add_vertex(r.pos)
	im.surface_end()
