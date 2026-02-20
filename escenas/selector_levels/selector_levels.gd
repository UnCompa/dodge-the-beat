extends Control
## Pantalla de selección de niveles con estética NEON / CYBERPUNK
## Requiere el autoload LevelManager en el proyecto.

# ── Nodos (se crean por código, no hace falta escena) ──
var _canvas: CanvasLayer
var _cards_container: HBoxContainer
var _title_label: Label
var _selected_index: int = 0
var _card_nodes: Array = []

# ── Shader neon scanlines (inline GLSL) ──
const SCANLINE_SHADER = """
shader_type canvas_item;
uniform float line_density : hint_range(100.0, 800.0) = 350.0;
uniform float intensity : hint_range(0.0, 0.4) = 0.08;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float scan = sin(UV.y * line_density) * 0.5 + 0.5;
	col.rgb -= scan * intensity;
	COLOR = col;
}
"""

func _ready():
	_build_scene()
	_animate_entrance()

# ══════════════════════════════════════════════
#  CONSTRUCCIÓN DE LA ESCENA
# ══════════════════════════════════════════════

func _build_scene():
	# Fondo oscuro base
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Grid background pattern
	_add_grid_background()

	# Scanline overlay con shader
	_add_scanline_overlay()

	# Partículas de fondo
	_create_background_particles()

	# Canvas layer principal para UI
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	# Contenedor raíz centrado
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	_canvas.add_child(root_vbox)

	# Cabecera
	_build_header(root_vbox)

	# Área central con las tarjetas
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_cards_container = HBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_container.add_theme_constant_override("separation", 24)
	_cards_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.add_child(_cards_container)

	# Margin container para padding lateral
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_child(margin)

	var inner = HBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 24)
	margin.add_child(inner)

	# Crear tarjetas
	var levels = LevelManager.levels
	for i in range(levels.size()):
		var card = _create_level_card(i, levels[i])
		inner.add_child(card)
		_card_nodes.append(card)

	# Footer con botón volver
	_build_footer(root_vbox)

func _add_grid_background():
	# Grid de líneas neon sutil usando un shader de grilla
	var grid = ColorRect.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.color = Color.TRANSPARENT

	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 line_color : source_color = vec4(0.0, 0.8, 1.0, 0.04);
uniform float grid_size : hint_range(20.0, 200.0) = 60.0;

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	vec2 grid = mod(uv, grid_size);
	float line_w = 1.0;
	float h = step(grid_size - line_w, grid.x) + step(grid_size - line_w, grid.y);
	COLOR = line_color * clamp(h, 0.0, 1.0);
}
"""
	shader_mat.shader = shader
	grid.material = shader_mat
	add_child(grid)

func _add_scanline_overlay():
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color.WHITE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = SCANLINE_SHADER
	mat.shader = shader
	overlay.material = mat
	add_child(overlay)

func _build_header(parent: Control):
	var header = MarginContainer.new()
	header.add_theme_constant_override("margin_top", 40)
	header.add_theme_constant_override("margin_bottom", 30)
	parent.add_child(header)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(vbox)

	# Línea decorativa superior
	var line_top = _make_neon_line(Color(0.0, 1.0, 0.9))
	vbox.add_child(line_top)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer1)

	# Subtítulo
	var sub = Label.new()
	sub.text = "// SISTEMA DE NAVEGACIÓN //"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.0, 0.8, 0.7, 0.7))
	vbox.add_child(sub)

	# Título principal
	_title_label = Label.new()
	_title_label.text = "SELECCIÓN DE NIVEL"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	vbox.add_child(_title_label)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	var line_bot = _make_neon_line(Color(0.0, 1.0, 0.9))
	vbox.add_child(line_bot)

func _build_footer(parent: Control):
	var footer = MarginContainer.new()
	footer.add_theme_constant_override("margin_bottom", 30)
	footer.add_theme_constant_override("margin_top", 20)
	parent.add_child(footer)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(hbox)

	var back_btn = _make_neon_button("← VOLVER AL MENÚ", Color(0.8, 0.0, 1.0))
	back_btn.pressed.connect(_on_back_pressed)
	hbox.add_child(back_btn)

# ══════════════════════════════════════════════
#  TARJETAS DE NIVEL
# ══════════════════════════════════════════════

func _create_level_card(index: int, level_data: Dictionary) -> PanelContainer:
	var is_locked = not LevelManager.is_unlocked(index)
	var is_completed = LevelManager.is_completed(index)
	var neon_color: Color = level_data.get("neon_color", Color(0.0, 1.0, 0.8))
	var card_color = neon_color if not is_locked else Color(0.3, 0.3, 0.35)

	# Panel exterior (tarjeta)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 260)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.14, 0.95)
	style.border_color = card_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(card_color.r, card_color.g, card_color.b, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 0)
	panel.add_theme_stylebox_override("panel", style)

	# Contenido vertical
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(margin)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	margin.add_child(inner)

	# Número de nivel con glow
	var num_label = Label.new()
	num_label.text = "%02d" % (index + 1)
	num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_label.add_theme_font_size_override("font_size", 52)
	num_label.add_theme_color_override("font_color", card_color)
	inner.add_child(num_label)

	# Línea separadora neon
	inner.add_child(_make_neon_line(card_color, 0.6))

	# Título
	var title = Label.new()
	title.text = level_data.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	inner.add_child(title)

	# Subtítulo / descripción
	var subtitle = Label.new()
	subtitle.text = level_data.get("subtitle", "")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(card_color.r, card_color.g, card_color.b, 0.7))
	inner.add_child(subtitle)

	# Spacer flexible
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	# Badge de estado
	var badge = Label.new()
	if is_locked:
		badge.text = "🔒 BLOQUEADO"
		badge.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	elif is_completed:
		badge.text = "✓ COMPLETADO"
		badge.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	else:
		badge.text = "▶ JUGAR"
		badge.add_theme_color_override("font_color", card_color)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	inner.add_child(badge)

	# Interactividad (solo si desbloqueado)
	if not is_locked:
		panel.mouse_entered.connect(_on_card_hovered.bind(panel, style, card_color, true))
		panel.mouse_exited.connect(_on_card_hovered.bind(panel, style, card_color, false))
		panel.gui_input.connect(_on_card_input.bind(index))
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		panel.modulate = Color(0.6, 0.6, 0.6, 0.7)

	return panel

# ══════════════════════════════════════════════
#  INTERACCIONES
# ══════════════════════════════════════════════

func _on_card_hovered(panel: PanelContainer, style: StyleBoxFlat, color: Color, hovering: bool):
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if hovering:
		tween.tween_property(panel, "scale", Vector2(1.06, 1.06), 0.15)
		style.shadow_size = 22
		style.border_color = color.lightened(0.3)
	else:
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)
		style.shadow_size = 12
		style.border_color = color

func _on_card_input(event: InputEvent, index: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_load_level(index)

func _on_back_pressed():
	LevelManager.go_to_main_menu()

func _load_level(index: int):
	print("[LevelSelect] Cargando nivel %d: %s" % [index, LevelManager.levels[index].title])
	# Efecto flash antes de cambiar escena
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.0, 1.0, 0.9, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.8, 0.12)
	tween.tween_property(flash, "color:a", 0.0, 0.18)
	tween.tween_callback(func(): LevelManager.load_level(index))

# ══════════════════════════════════════════════
#  ANIMACIÓN DE ENTRADA
# ══════════════════════════════════════════════

func _animate_entrance():
	# El título hace fade-in
	_title_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.6)

	# Las tarjetas caen desde arriba con stagger
	for i in range(_card_nodes.size()):
		var card = _card_nodes[i]
		var original_pos = card.position
		card.position.y -= 40
		card.modulate.a = 0.0
		var delay = 0.1 + i * 0.08

		var ct = create_tween()
		ct.tween_interval(delay)
		ct.tween_property(card, "modulate:a", 1.0, 0.35)
		ct.parallel().tween_property(card, "position:y", original_pos.y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ══════════════════════════════════════════════
#  HELPERS UI
# ══════════════════════════════════════════════

func _make_neon_line(color: Color, alpha: float = 1.0) -> ColorRect:
	var line = ColorRect.new()
	line.color = Color(color.r, color.g, color.b, alpha * 0.8)
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line

func _make_neon_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 44)
	btn.flat = true

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(color.r, color.g, color.b, 0.08)
	style_normal.border_color = color
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(color.r, color.g, color.b, 0.22)
	style_hover.border_color = color.lightened(0.2)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
	btn.add_theme_font_size_override("font_size", 13)
	return btn

# ══════════════════════════════════════════════
#  PARTÍCULAS DE FONDO
# ══════════════════════════════════════════════

func _create_background_particles():
	var viewport_size = get_viewport().get_visible_rect().size

	# Partículas pequeñas (polvo neon)
	_spawn_particles(viewport_size, 60, 3.0, 10.0, 1.0, 2.5, Color(0.0, 0.9, 1.0, 0.5))
	# Partículas medianas (destellos)
	_spawn_particles(viewport_size, 20, 5.0, 6.0, 2.0, 5.0, Color(0.8, 0.0, 1.0, 0.4))

func _spawn_particles(vp: Vector2, amount: int, lifetime: float, speed_max: float, scale_min: float, scale_max: float, color: Color):
	var particles = GPUParticles2D.new()
	particles.position = vp / 2
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	add_child(particles)
	move_child(particles, 1)

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp.x / 2.0, vp.y / 2.0, 0)
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = speed_max * 0.3
	mat.initial_velocity_max = speed_max
	mat.scale_min = scale_min
	mat.scale_max = scale_max
	mat.scale_curve = _create_scale_curve()
	mat.color = color
	mat.color_ramp = _create_fade_gradient(color)
	particles.process_material = mat
	particles.texture = _create_circle_texture()
	particles.emitting = true

func _create_scale_curve() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.3, 1))
	curve.add_point(Vector2(1, 0))
	var tex = CurveTexture.new()
	tex.curve = curve
	return tex

func _create_fade_gradient(color: Color = Color.WHITE) -> GradientTexture1D:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 0))
	gradient.add_point(0.5, Color(color.r, color.g, color.b, color.a))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0))
	var tex = GradientTexture1D.new()
	tex.gradient = gradient
	return tex

func _create_circle_texture() -> ImageTexture:
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist = center.distance_to(Vector2(x, y))
			var alpha = clamp(1.0 - (dist / (size / 2.0)), 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
