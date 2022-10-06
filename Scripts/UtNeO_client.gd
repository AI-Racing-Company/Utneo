extends Node2D

var my_id = 0
var my_card_num = 0
var my_cards = []
var my_card_nodes = []

var peer = null

func _ready():
	get_viewport().connect("size_changed", self, "resized")
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(global.ip, global.port)
	peer.COMPRESS_ZLIB
	get_tree().network_peer = peer
	print(get_tree().network_peer)
	get_node("ClientText").text = "Connected To " + global.ip + ":" + str(global.port)
	get_tree().connect("connected_to_server", self, "connected_to_server")
	get_tree().connect("connection_failed", self, "connection_failed")
	get_tree().connect("server_disconnected", self, "serversided_disconnect")


func resized():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	var add = width / (my_card_num+1)
	for i in range(len(my_card_nodes)):
		var vec = Vector2((i+1)*add - 75/2,height-100)
		my_card_nodes[i].set_global_position(vec)

func add_card():
	rpc_id(0, "add_card", my_id)

puppet func master_add_card(card):
	my_card_num += 1

	card.set_size(Vector2(75,100))
	get_node("Cards").call_deferred("add_child", card)

	my_card_nodes.append(card)
	resized()

func card_removed(card):
	my_card_nodes.erase(card)
	my_card_num -= 1


func hand_card_pressed(card):
	var value = card.name.split("_")
	print(int(value[1]))

func button_pressed(switch):
	print(switch)
