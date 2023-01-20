extends Node2D

var nue
var login_key
puppet var my_turn = false
var my_cards = []
var my_id

var calc_types = [global.btn_modes.add, global.btn_modes.sub, global.btn_modes.mul, global.btn_modes.div, global.btn_modes.pot, global.btn_modes.sqr]

var peer = null
var current_calc = ["","",""] # Array for Operation, value 1, value 2, name 1, name 2, card_id 1 and card_id 2
var possible_solutions = {"0":[], "1":[], "2":[], "3":[], "4":[], "5":[], "6":[], "7":[],"8":[],"9":[]}

var current_card

func _ready():
	print("I am Coltin, the first ever Utneo Bot")
	print(global.ip, ":", global.port)
	peer = NetworkedMultiplayerENet.new()
	
	
	
	var error : int = peer.create_client(global.ip, global.port)
	
	if error == 0: #if no errors...
		print("err:",error)
		get_tree().network_peer = peer
		print(peer.is_connected("peer_connected", peer, "login"))
		
		print(get_tree().network_peer)
		get_tree().connect("server_disconnected", self, "serversided_disconnect")
		yield(get_tree().create_timer(1), "timeout")
		print(peer.is_connected("peer_connected", peer, "login"))
		
		set_network_master(1)
		rpc_config("connection_established", 1)
		
		rpc_id(1, "login", my_id, "coltin", -1, -1)
		print("afterRPC")
	else: #if an error occurred while trying to join a hosted session...
		print("ERROR while executing create_client(), error code: ", error);
	
	

puppet func bot_init(key, name):
	login_key = key
	rpc_id(1, "give_key", my_id, login_key)
	get_node("Label").text = "Hello, I am " + name

puppet func connection_established(id):
	my_id = id

puppet func startOfRound():
	#yield(get_tree().create_timer(2), "timeout")
	print(my_cards)
	current_calc = ["","",""]
	calc_possible()
	print("done calculating")
	if possible_solutions[str(current_card)].size() > 0:
		print("can push")
		var pc0 = possible_solutions[str(current_card)][0]
		current_calc = [calc_types[pc0[2]], str(pc0[0]), str(pc0[1])]
		print("pushing ", current_calc)
		rpc_id(1,"cards_pushed",my_id,current_calc)
		calc_possible()
		print("pushed")
	else:
		if my_cards.count(current_card) > 0:
			current_calc = ["", str(current_card), ""]
			print("pushed 1 card")
		else:
			print("drew")
			rpc_id(1, "add_card", my_id)

func calc_possible():
	possible_solutions = {"0":[], "1":[], "2":[], "3":[], "4":[], "5":[], "6":[], "7":[],"8":[],"9":[]}
	for i in range(my_cards.size()):
		var c1 = my_cards[i]
		for j in range(i+1, my_cards.size()):
			var sols = [-1,-1,-1,-1,-1,-1]
			var c2 = my_cards[j]
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
				if sols[k] >= 0:
					possible_solutions[str(sols[k])].append([c1,c2,k])
		

puppet func master_add_card(rand):
	my_cards.append(rand)
	calc_possible()

puppet func card_removed(_newPoint):
	
	if(current_calc[1] != ""):
		my_cards.erase(int(current_calc[1]))

	if(current_calc[2] != ""):
		my_cards.erase(int(current_calc[2]))

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


