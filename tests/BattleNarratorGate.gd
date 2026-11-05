extends Node
## CI narration gate: only a deliberate completion event may release a move.
signal narration_released
var calls: int=0
var messages: Array[String]=[]

func _say_and_wait(message: String) -> void:
    calls+=1
    messages.append(message)
    await narration_released
