extends RefCounted

const FUNDO: Color = Color("080d18")
const PAINEL: Color = Color("111925")
const TEXTO: Color = Color("e1dfd5")
const SUAVE: Color = Color("aab5c6")
const OURO: Color = Color("c5a779")
const AZUL: Color = Color("759cbc")
const VERMELHO: Color = Color("b9787a")
const RARIDADES: Array[Color] = [Color("aab2bf"), Color("7bacbe"), Color("bb99c4"), Color("d3ad6a")]

static func fonte(titulo: bool = false) -> Font:
	return load("res://fontes/Cinzel.ttf" if titulo else "res://fontes/Texto.ttf") as Font

static func criar() -> Theme:
	var tema: Theme = Theme.new()
	tema.default_font = fonte()
	tema.default_font_size = 18
	tema.set_color("font_color", "Label", TEXTO)
	tema.set_color("font_color", "Button", TEXTO)
	tema.set_color("font_hover_color", "Button", Color.WHITE)
	tema.set_color("font_pressed_color", "Button", OURO)
	tema.set_color("font_disabled_color", "Button", Color("727d8b"))
	tema.set_stylebox("normal", "Button", caixa(PAINEL, Color("536173")))
	tema.set_stylebox("hover", "Button", caixa(Color("1b2737"), OURO))
	tema.set_stylebox("pressed", "Button", caixa(Color("2a2d30"), OURO))
	tema.set_stylebox("focus", "Button", caixa(Color(0, 0, 0, 0), AZUL))
	tema.set_stylebox("disabled", "Button", caixa(Color("101620"), Color("293341")))
	tema.set_constant("h_separation", "GridContainer", 8)
	tema.set_constant("v_separation", "GridContainer", 8)
	tema.set_constant("separation", "VBoxContainer", 12)
	tema.set_stylebox("background", "ProgressBar", trilho(Color("090d15")))
	tema.set_stylebox("fill", "ProgressBar", trilho(Color("98535a")))
	return tema

static func caixa(cor: Color = PAINEL, borda: Color = Color("384658")) -> StyleBoxFlat:
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = borda
	estilo.set_border_width_all(1)
	estilo.border_width_bottom = 2
	estilo.corner_radius_top_left = 2
	estilo.corner_radius_bottom_right = 2
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	return estilo

static func icone(indice: int) -> Texture2D:
	var textura: Texture2D = load("res://arte/itens.png") as Texture2D
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = textura
	var celula: Vector2 = textura.get_size() / 4.0
	atlas.region = Rect2(Vector2(float(indice % 4) * celula.x, floorf(float(indice) / 4.0) * celula.y), celula)
	atlas.filter_clip = true
	return atlas

static func retrato(indice: int) -> Texture2D:
	if not ResourceLoader.exists("res://arte/retratos.png"):
		return icone(14)
	var textura: Texture2D = load("res://arte/retratos.png") as Texture2D
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = textura
	var celula: Vector2 = textura.get_size() / Vector2(4, 2)
	atlas.region = Rect2(Vector2(float(indice % 4) * celula.x, floorf(float(indice) / 4.0) * celula.y), celula)
	atlas.filter_clip = true
	return atlas

static func texto(conteudo: String, tamanho: int = 18, cor: Color = TEXTO, titulo: bool = false) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = conteudo
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	if titulo:
		rotulo.add_theme_font_override("font", fonte(true))
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo

static func trilho(cor: Color) -> StyleBoxFlat:
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.content_margin_left = 0
	estilo.content_margin_right = 0
	estilo.content_margin_top = 0
	estilo.content_margin_bottom = 0
	return estilo
