extends Node

var nue

var my_cards = []
var my_id = 0

var peer = null
var current_calc = ["","",""] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var possible_solutions = []

var current_card


func _ready():
	nue = get_viewport().connect("size_changed", self, "resized")
	nue = get_tree().connect("server_disconnected", self, "serversided_disconnect")
	
	rpc_id(1, "give_key", my_id, global.login_key)



puppet func startOfRound():
	current_calc = ["","",""]
	calc_possible()

func calc_possible():
	for i in range(my_cards.size()):
		var c1 = my_cards[i]
		for j in range(i, my_cards.size()):
			var c2 = my_cards[j]
			var sol_a = (c1+c2)%10
			var sol_s = -1
			if c1>=c2:
				sol_s = c1-c2
			var sol_m = (c1*c2)%10
			var sol_d = -1
			if c2 != 0:
				sol_d = int(c1/c2)
			var sol_e = int(pow(c1,c2))%10
			var sol_r = -1
			if c1 != 0:
				sol_r = int(pow(c2,float(1)/c1))
		

puppet func master_add_card(rand):
	my_cards.append(rand)

puppet func card_removed(newPoint):
	
	if(current_calc[3] != ""):
		my_cards.remove(current_calc[3])

	if(current_calc[4] != ""):
		my_cards.remove(current_calc[4])

	current_calc = ["","",""]


puppet func r_t_h(newRT):
	pass

puppet func endOfRound():
	pass

puppet func set_current_card(c):
	current_card = c
	
puppet func update_player_list(sendstr):
	pass

puppet func player_done(_p_name, _pos):
	pass

puppet func game_end():
	pass

puppet func set_current_player(_pname):
	pass

puppet func set_past_calc(newText):
	pass

puppet func my_end_f():
	pass

puppet func set_winner(win):
	pass

puppet func continue_game():
	pass



