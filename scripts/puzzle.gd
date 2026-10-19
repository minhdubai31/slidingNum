class_name SlidePuzzle
extends RefCounted

var dimension: int = 4
var cells: Array[int] = []
var history: Array[int] = []
var redo_stack: Array[int] = []
var moves: int = 0
var solution: Array[int] = []

func reset(n: int, mix: bool = true, shuffle_seed: int = -1) -> void:
	dimension = n
	cells.clear()
	for i in range(1, n * n):
		cells.append(i)
	cells.append(0)
	history.clear()
	redo_stack.clear()
	moves = 0
	solution.clear()
	if mix:
		var rng := RandomNumberGenerator.new()
		if shuffle_seed >= 0:
			rng.seed = shuffle_seed
		else:
			rng.randomize()
		# Legal moves from the goal guarantee every generated board is solvable.
		var previous: int = -1
		for step in range(n * n * 4):
			var blank: int = cells.find(0)
			var choices: Array[int] = neighbors(blank)
			choices.erase(previous)
			var next: int = choices[rng.randi_range(0, choices.size() - 1)]
			solution.push_front(cells[next])
			cells[blank] = cells[next]
			cells[next] = 0
			previous = blank
		if solved():
			var next: int = neighbors(cells.find(0))[0]
			var blank: int = cells.find(0)
			cells[blank] = cells[next]
			cells[next] = 0
			solution.push_front(cells[blank])

func neighbors(index: int) -> Array[int]:
	var result: Array[int] = []
	for other in range(cells.size()):
		if absi(other % dimension - index % dimension) + absi(other / dimension - index / dimension) == 1:
			result.append(other)
	return result

func can_move(index: int) -> bool:
	return index >= 0 and index < cells.size() and cells[index] != 0 and neighbors(cells.find(0)).has(index)

func slide(index: int) -> bool:
	if not can_move(index):
		return false
	var blank: int = cells.find(0)
	var value: int = cells[index]
	if not solution.is_empty() and solution[0] == value:
		solution.pop_front()
	else:
		solution.push_front(value)
	history.append(blank)
	redo_stack.clear()
	cells[blank] = cells[index]
	cells[index] = 0
	moves += 1
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	var previous_blank: int = history.pop_back()
	var blank: int = cells.find(0)
	# Redoing slides the tile now at the gap's old spot back into it.
	redo_stack.append(blank)
	var value: int = cells[previous_blank]
	if not solution.is_empty() and solution[0] == value:
		solution.pop_front()
	else:
		solution.push_front(value)
	cells[blank] = cells[previous_blank]
	cells[previous_blank] = 0
	moves = maxi(0, moves - 1)
	return true

# Replays the most recently undone move; a new move clears the redo chain.
func redo() -> bool:
	if redo_stack.is_empty():
		return false
	var remaining: Array[int] = redo_stack.duplicate()
	var index: int = remaining.pop_back()
	if not slide(index):
		return false
	redo_stack = remaining
	return true

func solved() -> bool:
	for i in range(cells.size() - 1):
		if cells[i] != i + 1:
			return false
	return not cells.is_empty() and cells.back() == 0
