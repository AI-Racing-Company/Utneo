extends Node

var max_recursion_depth = 3

var rounds = 0;

var nue
var login_key
var my_turn = false
var my_cards = [0,0,0,0,0,0,0,0,0,0]
var my_id = 0

var calced = []

var current_index_array = [-1, "","", -1]
var use_calc = []

var calc_types = [global.btn_modes.add, global.btn_modes.sub, global.btn_modes.mul, global.btn_modes.div, global.btn_modes.pot, global.btn_modes.sqr]

var current_calc = ["","",""] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var possible_solutions = []

var current_card

var runcount = 0

func _ready():
	pass


func give_id(id):
	my_id = id

func startOfRound():
	runcount = 0
	calced = []
	rounds += 1
	current_calc = ["","",""]
	possible_solutions = []
	
	var time_before = OS.get_ticks_msec()
	calc_possible(my_cards, current_card, 0)
	calc_use_calc()
	var total_time = OS.get_ticks_msec() - time_before
	
	print("rc: ", runcount)
	print("ta: ", calced.size())
	print("tt: ", total_time)
	print("\n\n")
	
	#print("     0  1  2  3  4  5  6  7  8  9")
	#print("mc: ", my_cards)
	#print("cc: ", current_card)
	if typeof(use_calc[2]) != TYPE_STRING:
		current_calc = [calc_types[use_calc[2]], use_calc[0], use_calc[1]]
		#print("pushing ", current_calc)
		get_parent().cards_pushed(my_id,current_calc)
		
	else:
		if my_cards[current_card] > 0:
			current_calc = ["", str(current_card), ""]
			get_parent().cards_pushed(my_id,current_calc)
			#print("pushed 1 card: " + str(current_card))
		else:
			#print("drew")
			get_parent().add_card(my_id)
	
	#print("rounds: ", rounds)

func calc_possible(cards_left, goal, depth):
	runcount += 1;
	for i in range(10):
		if cards_left[i] == 0:
			continue
		var c1 = i


		for j in range(10):
			var c2 = j
			if (j == i and cards_left[i] < 2) or cards_left[j] == 0:
				continue
			var sols = [-1,-1,-1,-1,-1,-1]
			
			sols[0] = (c1+c2)%10	# addition
			
			if c1>=c2:
				sols[1] = c1-c2
				
			sols[2] = (c1*c2)%10	#multiplication
			
			if c2 != 0:
				sols[3] = int(c1/c2)
				
			sols[4] = int(pow(c1,c2))%10	#power
			
			if c1 != 0:
				sols[5] = int(pow(c2,float(1)/c1))

			for k in range(sols.size()):
				if sols[k] == goal:
					if depth == 0:
						current_index_array = [c1,c2,k,depth]
						possible_solutions.append(current_index_array)
					else:
						current_index_array[3] = depth
						possible_solutions.append(current_index_array)
					var ncc = cards_left.duplicate()
					ncc[c1] = ncc[c1]-1;
					ncc[c2] = ncc[c2]-1;
					if depth < max_recursion_depth and calced.find(ncc) == -1:
						calced.append(ncc.duplicate())
						calc_possible(ncc, c2, depth+1)

func calc_use_calc():
	var highest = [-1,-1]
	for i in range(possible_solutions.size()):
		if possible_solutions[i][3] > highest[1]:
			highest = [i, possible_solutions[i][3]]
	if highest[0] != -1:
		use_calc = possible_solutions[highest[0]]
		use_calc[0] = str(use_calc[0])
		use_calc[1] = str(use_calc[1])
	else:
		use_calc = ["","",""]
func master_add_card(rand):
	for i in range(10):
		my_cards[i] += rand.count(i)
	#print("got cards")

func card_removed(_newPoint):

	if(current_calc[1] != ""):
		my_cards[int(current_calc[1])] -= 1

	if(current_calc[2] != ""):
		my_cards[int(current_calc[2])] -= 1

	current_calc = ["","",""]


func set_variable(variable, val):
	match variable:
		"my_turn":
			my_turn = val


func set_current_card(val):
	current_card = val
