extends SceneTree

func _init() -> void:
	var puzzle := SlidePuzzle.new()
	for n in [3, 4, 5]:
		for trial in range(40):
			puzzle.reset(n)
			assert(not puzzle.solved(), "Shuffle must not start solved")
			var values: Array[int] = puzzle.cells.duplicate()
			values.sort()
			for i in range(n * n):
				assert(values[i] == i, "Each tile must occur once")
			var original: Array[int] = puzzle.cells.duplicate()
			var index: int = puzzle.neighbors(puzzle.cells.find(0)).pick_random()
			assert(puzzle.slide(index))
			assert(puzzle.moves == 1)
			assert(puzzle.undo())
			assert(puzzle.cells == original)
			assert(puzzle.moves == 0)
			assert(not puzzle.slide(puzzle.cells.find(0)))
			assert(not puzzle.undo())
			var check_puzzle := SlidePuzzle.new()
			check_puzzle.dimension = n
			check_puzzle.cells = puzzle.cells.duplicate()
			var solution: Array[int] = puzzle.solution.duplicate()
			for value in solution:
				assert(check_puzzle.slide(check_puzzle.cells.find(value)), "Every hint step must be legal")
			assert(check_puzzle.solved(), "Stored hint path must solve shuffle")
			# Independent inversion parity check verifies shuffle solvability.
			var inversions: int = 0
			for a in range(puzzle.cells.size()):
				for b in range(a + 1, puzzle.cells.size()):
					if puzzle.cells[a] != 0 and puzzle.cells[b] != 0 and puzzle.cells[a] > puzzle.cells[b]:
						inversions += 1
			if n % 2 == 1:
				assert(inversions % 2 == 0)
			else:
				var row_from_bottom: int = n - puzzle.cells.find(0) / n
				assert((inversions + row_from_bottom) % 2 == 1)
		puzzle.reset(n, false)
		assert(puzzle.solved())
		assert(puzzle.slide(n * n - 2))
		assert(not puzzle.solved())
		assert(puzzle.slide(n * n - 1))
		assert(puzzle.solved())
	print("PASS: 120 shuffled puzzles, parity, legal moves, undo, solved detection")
	quit()
