extends RefCounted
## Arquivo binário de Variants sem objetos executáveis; versão e estrutura validadas.

const CAMINHO: String = "user://jornada-v05.dat"
const VERSAO: int = 1

static func guardar(dados: Dictionary, caminho: String = CAMINHO) -> Error:
	var temporario: String = caminho + ".novo"
	var arquivo: FileAccess = FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		return FileAccess.get_open_error()
	arquivo.store_var({"versao": VERSAO, "jornada": dados}, false)
	arquivo.flush()
	var erro: Error = arquivo.get_error()
	arquivo.close()
	if erro != OK:
		return erro
	return DirAccess.rename_absolute(temporario, caminho)

static func carregar(caminho: String = CAMINHO) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var arquivo: FileAccess = FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return {}
	var conteudo: Variant = arquivo.get_var(false)
	arquivo.close()
	if not conteudo is Dictionary:
		return {}
	var pacote: Dictionary = conteudo
	if int(pacote.get("versao", -1)) != VERSAO or not pacote.get("jornada") is Dictionary:
		return {}
	return pacote["jornada"]
