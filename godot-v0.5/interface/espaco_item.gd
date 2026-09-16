extends Button

signal mover(origem: int, destino: int)
const Itens = preload("res://dados/itens.gd")
const Tema = preload("res://interface/tema.gd")
var indice: int = -1
var instancia: Dictionary = {}
var barra: ProgressBar
var arrastavel: bool = true

func configurar(item: Dictionary, posicao: int, compacto: int = 0) -> void:
	indice = posicao
	instancia = item
	custom_minimum_size = Vector2(0, 126 if compacto == 0 else (92 if compacto == 1 else 68))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var margem: MarginContainer = MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 4)
	margem.add_theme_constant_override("margin_right", 4)
	margem.add_theme_constant_override("margin_top", 4)
	margem.add_theme_constant_override("margin_bottom", 6)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 2)
	margem.add_child(coluna)
	if item.is_empty():
		var vazio: Label = Tema.texto("%d\nVazio" % (indice + 1), 15, Tema.SUAVE)
		vazio.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		coluna.add_child(vazio)
		return
	var dados: Dictionary = Itens.dados(item)
	var cor: Color = Tema.RARIDADES[int(dados["nivel"])]
	add_theme_stylebox_override("normal", Tema.caixa(Color("0b111c"), cor.darkened(0.4)))
	var imagem: TextureRect = TextureRect.new()
	imagem.texture = Tema.icone(int(dados["icone"]))
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.custom_minimum_size = Vector2(0, 62 if compacto == 0 else 42)
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(imagem)
	if compacto < 2:
		var nome_item: Label = Tema.texto(str(dados["curto"]), 14 if compacto == 0 else 12, cor)
		nome_item.size_flags_vertical = Control.SIZE_EXPAND_FILL
		nome_item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		coluna.add_child(nome_item)
	barra = ProgressBar.new()
	barra.custom_minimum_size.y = 5
	barra.show_percentage = false
	barra.max_value = 1.0
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.add_theme_stylebox_override("fill", Tema.trilho(cor))
	coluna.add_child(barra)
	if compacto == 0:
		barra.visible = false

func selecionar(ativo: bool) -> void:
	if ativo:
		add_theme_stylebox_override("normal", Tema.caixa(Color("29313a"), Tema.OURO))
	else:
		var borda: Color = Tema.RARIDADES[int(instancia["nivel"])].darkened(0.4) if not instancia.is_empty() else Color("384658")
		add_theme_stylebox_override("normal", Tema.caixa(Color("0b111c"), borda))

func pulsar() -> void:
	modulate = Color(1.5, 1.3, 1.1)
	var animacao: Tween = create_tween()
	animacao.tween_property(self, "modulate", Color.WHITE, 0.3)

func _get_drag_data(_posicao: Vector2) -> Variant:
	if instancia.is_empty() or not arrastavel:
		return null
	var previa: TextureRect = TextureRect.new()
	previa.texture = Tema.icone(int(Itens.dados(instancia)["icone"]))
	previa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	previa.custom_minimum_size = Vector2(84, 84)
	set_drag_preview(previa)
	return {"espaco": indice}

func _can_drop_data(_posicao: Vector2, dados: Variant) -> bool:
	return arrastavel and dados is Dictionary and (dados as Dictionary).has("espaco")

func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	if _can_drop_data(_posicao, dados):
		mover.emit(int((dados as Dictionary)["espaco"]), indice)
