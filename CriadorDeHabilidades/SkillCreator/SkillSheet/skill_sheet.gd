class_name SkillSheet extends ColorRect

@onready var sheet_panel: PanelContainer = $SheetPanel
@onready var result_text: RichTextLabel = $SheetPanel/VBoxContainer/ResultText

@onready var save_text_button: Button = $SheetPanel/VBoxContainer/HBoxContainer/SaveTextButton
@onready var save_image_button: Button = $SheetPanel/VBoxContainer/HBoxContainer/SaveImageButton
@onready var close_button: Button = $SheetPanel/VBoxContainer/HBoxContainer/CloseButton

@onready var text_file_dialog: FileDialog = $TextFileDialog
@onready var image_file_dialog: FileDialog = $ImageFileDialog

func _ready() -> void:
	hide() # Começa invisível
	
	close_button.pressed.connect(hide)
	
	save_text_button.pressed.connect(text_file_dialog.popup_centered)
	save_image_button.pressed.connect(image_file_dialog.popup_centered)
	
	text_file_dialog.file_selected.connect(_on_save_text_selected)
	image_file_dialog.file_selected.connect(_on_save_image_selected)

# A PlayerScreen vai chamar esta função e passar os dados
func build_sheet(skill_name: String, skill: CraftedSkill, final_tier: int, final_cost: float, stats: Dictionary) -> void:
	# Pega os tipos combinados (ex: OFENSIVO / TATICO)
	var type_strings: Array[String] = []
	for type_int in skill.combined_types:
		type_strings.append(CharacteristicData.characteritstic_types.keys()[type_int])
	var final_types = " / ".join(type_strings)
	
	# Inicia a string já forçando a cor base para preto
	var final_text: String = "[color=black]"
	
	# CABEÇALHO
	final_text += "[center][b][font_size=24]=== " + skill_name.to_upper() + " ===[/font_size][/b][/center]\n\n"
	
	# ESTATÍSTICAS PRINCIPAIS
	final_text += "[b]Tier Final:[/b] " + str(final_tier) + "\n"
	final_text += "[b]Tipos:[/b] " + final_types + "\n"
	# Alterado de cyan para darkblue
	final_text += "[b]Custo de Mana:[/b] [color=darkblue]" + str(final_cost) + " PM[/color]\n"
	final_text += "[b]Fator de Custo (Árvore):[/b] " + str(skill.total_cost) + "\n"
	final_text += "[b]----------------------------------------[/b]\n"
	
	# PARÂMETROS DA HABILIDADE
	final_text += "[b]Sincronia:[/b] " + stats["sincronia"] + "\n"
	final_text += "[b]Velocidade:[/b] " + stats["velocidade"] + "\n"
	final_text += "[b]Alcance:[/b] " + stats["alcance"] + "\n"
	
	# Mostra o Alvo e, se for área, mostra o tamanho
	if stats.has("area_shape"):
		final_text += "[b]Alvo:[/b] Área (" + stats["area_shape"] + " de " + stats["area_size"] + ")\n"
	else:
		final_text += "[b]Alvo:[/b] " + stats["alvo"] + "\n"
		
	# Mostra Defesa Alvo apenas se não for "Nenhuma"
	if stats["defesa"] != "Nenhuma (Não é ataque)":
		# Alterado de orange para darkred para melhor contraste no branco
		final_text += "[b]Defesa Alvo:[/b] [color=darkred]" + stats["defesa"] + "[/color]\n"
		
	final_text += "[b]Duração:[/b] " + stats["duracao"] + "\n"
	final_text += "[b]Usos:[/b] " + stats["usos"] + " (" + stats["recuperacao"] + ")\n"
	final_text += "[b]----------------------------------------[/b]\n\n"
	
	# EFEITOS (CARACTERÍSTICAS DA ÁRVORE)
	final_text += "[b]CARACTERÍSTICAS APLICADAS:[/b]\n\n"
	
	for node_data in skill.selected_nodes:
		var char_data = node_data.characteristic
		final_text += "[b]► " + char_data.name + "[/b]"
		if char_data.material_cost != "":
			# Alterado de yellow para darkblue a seu pedido
			final_text += " [color=darkblue](Material: " + char_data.material_cost + ")[/color]"
		final_text += "\n"
		
		if char_data.description != "":
			final_text += char_data.description + "\n\n"
		else:
			final_text += "[i]Sem descrição mecânica.[/i]\n\n"
			
	# Fecha a tag da cor preta no final do texto
	final_text += "[/color]"
			
	result_text.text = final_text
	show()

func _on_save_text_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# get_parsed_text() remove as tags [b], [color], etc, deixando o texto limpo!
		file.store_string(result_text.get_parsed_text())
		file.close()
		print("Ficha salva em texto: ", path)

func _on_save_image_selected(path: String) -> void:
	# Esconde os botões temporariamente para eles não saírem na foto
	save_text_button.hide()
	save_image_button.hide()
	close_button.hide()
	
	# Espera o Godot desenhar a tela sem os botões
	await get_tree().process_frame 
	await get_tree().process_frame 
	
	# Tira uma "foto" da tela inteira
	var full_image: Image = get_viewport().get_texture().get_image()
	
	# Descobre a posição e tamanho exatos do painel da ficha na tela
	var rect: Rect2i = Rect2i(sheet_panel.global_position, sheet_panel.size)
	
	# Recorta a foto para ter apenas a ficha
	var cropped_image: Image = full_image.get_region(rect)
	
	# Salva no disco
	cropped_image.save_png(path)
	print("Ficha salva em imagem: ", path)
	
	# Devolve os botões
	save_text_button.show()
	save_image_button.show()
	close_button.show()
