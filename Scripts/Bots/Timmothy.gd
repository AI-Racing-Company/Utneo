extends Node2D

var max_recursion_depth = 5

var nue
var login_key
puppet var my_turn = false
var my_cards = [0,0,0,0,0,0,0,0,0,0]
var my_id = 0

var current_index = -1
var current_index_array
var use_calc = []

var calc_types = [global.btn_modes.add, global.btn_modes.sub, global.btn_modes.mul, global.btn_modes.div, global.btn_modes.pot, global.btn_modes.sqr]

var peer = null
var current_calc = ["","",""] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var possible_solutions = []

var current_card

func _ready():
	peer = NetworkedMultiplayerENet.new()
	var error : int = peer.create_client(global.ip, global.port)

	if error == 0: #if no errors...
		get_tree().network_peer = peer
		nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
		yield(get_tree().create_timer(2), "timeout")
		rpc_id(1, "login", my_id, global.username, -1, -1)
		print("Connected")
	else: #if an error occurred while trying to join a hosted session...
		print("ERROR while executing create_client(), error code: ", error);



puppet func bot_init(key, name):
	login_key = key
	rpc_id(1, "give_key", my_id, login_key)
	get_node("Label").text = "Hello, I am " + name

puppet func connection_established(id):
	my_id = id

puppet func startOfRound():
	print("Strating new round")
	#yield(get_tree().create_timer(2), "timeout")

	print(my_cards)
	print("My current cards: ", my_cards.size())
	current_calc = ["","",""]
	possible_solutions = []
	print("card to reach: ", current_card)
	var time_before = OS.get_ticks_msec()
	calc_possible(my_cards, current_card, 0)
	var total_time = OS.get_ticks_msec() - time_before
	print("Time taken: " + str(total_time))
	print("Diffrent possibilities: ", possible_solutions.size())
	if use_calc != []:
		current_calc = [calc_types[use_calc[2]] if str(use_calc[2]) != "" else "", str(use_calc[0]), str(use_calc[1])]
		print("pushing ", current_calc)
		rpc_id(1,"cards_pushed",my_id,current_calc)
		print("pushed")
	else:
		if my_cards.count(current_card) > 0:
			current_calc = ["", str(current_card), ""]
			rpc_id(1,"cards_pushed", my_id, current_calc)
			print("pushed 1 card: " + str(current_card))
		else:
			print("drew")
			rpc_id(1, "add_card", my_id)

func calc_possible(cards_left, goal, depth):
	
	use_calc = []

	for i in range(cards_left.size()):
		if cards_left[i] == 0:
			continue
		var c1 = i
		
		if c1 == goal:
			if depth == 0:
				current_index_array = [c1,"","",depth]
				possible_solutions.append(current_index_array)
				current_index = possible_solutions.find(current_index_array)
			else:
				current_index_array[3] = depth
				possible_solutions[possible_solutions.size() - 1] = current_index_array
			var ncc = cards_left.duplicate()
			ncc[c1] = ncc[c1]-1;
			if depth < max_recursion_depth:
				calc_possible(ncc, c1, depth+1)

		for j in range(i, cards_left.size()):
			

			var c2 = j
			if (j == i and cards_left[i] < 2) or cards_left[j] == 0:
				continue
			var sols = [-1,-1,-1,-1,-1,-1]
			sols[0] = (c1+c2)%10
			sols[1] = -1
			if c1>=c2:
				sols[1] = c1-c2
			sols[2] = (c1*c2)%10
			sols[3] = -1
			if c2 != 0:
				sols[3] = int(c1/c2)
			sols[4] = int(pow(c1,c2))%10
			sols[5] = -1
			if c1 != 0:
				sols[5] = int(pow(c2,float(1)/c1))

			for k in range(sols.size()):
				if sols[k] == goal:
					if depth == 0:
						current_index_array = [c1,c2,k,depth]
						possible_solutions.append(current_index_array)
						current_index = possible_solutions.find(current_index_array)
					else:
						current_index_array[3] = depth
						possible_solutions[possible_solutions.size() - 1] = current_index_array
					var ncc = cards_left.duplicate()
					ncc[c1] = ncc[c1]-1;
					ncc[c2] = ncc[c2]-1;
					print("depth: ", depth)
					if depth < max_recursion_depth:
						calc_possible(ncc, c2, depth+1)

	if(depth == 0):
		var highest = [-1,-1]
		for i in range(possible_solutions.size()):
			if possible_solutions[i][3] > highest[1]:
				highest = [i, possible_solutions[i][3]]
		if highest[0] != -1:
			use_calc = possible_solutions[highest[0]]


puppet func master_add_card(rand):
	for i in range(10):
		my_cards[i] += rand.count(i)
	print("got cards")

puppet func card_removed(_newPoint):

	if(current_calc[1] != ""):
		my_cards[int(current_calc[1])] -= 1

	if(current_calc[2] != ""):
		my_cards[int(current_calc[2])] -= 1

	current_calc = ["","",""]


puppet func r_t_h(_newRT):
	pass

puppet func endOfRound():
	pass

puppet func set_current_card(c):
	current_card = c

puppet func update_player_list(_sendstr):
	pass

puppet func player_done(_p_name, _pos):
	pass

puppet func game_end():
	pass

puppet func set_current_player(_pname):
	pass

puppet func set_past_calc(_newText):
	pass

puppet func my_end_f():
	pass

puppet func set_winner(_win):
	pass

puppet func continue_game():
	pass

func serversided_disconnect():
	print("Byebye")
	pass
