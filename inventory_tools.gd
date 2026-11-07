extends RefCounted
var g
var sort_mode=0
var filter_mode=0
const PER_PAGE=8
func _init(game):g=game
func filtered() -> Array:
	var result=[]
	for i in range(g.inventory.size()):
		var item=g.inventory[i]
		if item.slot!=g.equipment_slot:continue
		var equipped=g.equipped.get(item.slot,-1)==i
		if filter_mode==1 and not equipped:continue
		if filter_mode==2 and equipped:continue
		if filter_mode==3 and not item.get("kept",false):continue
		result.append(i)
	result.sort_custom(func(a,b):
		var x=g.inventory[a];var y=g.inventory[b]
		if sort_mode==0:return int(x.level)>int(y.level) if x.level!=y.level else int(x.rarity)>int(y.rarity) if x.rarity!=y.rarity else a<b
		if sort_mode==1:return int(x.rarity)>int(y.rarity) if x.rarity!=y.rarity else int(x.level)>int(y.level) if x.level!=y.level else a<b
		return str(x.name)<str(y.name) if x.name!=y.name else a<b)
	return result
func handle(id: String) -> bool:
	if g.mode!="equipment":return false
	if id=="inventory_sort":sort_mode=(sort_mode+1)%3;g.inventory_page=0;return true
	if id=="inventory_filter":filter_mode=(filter_mode+1)%4;g.inventory_page=0;return true
	if id=="keep_selected" and g.selected_item>=0 and g.selected_item<g.inventory.size():g.inventory[g.selected_item]["kept"]=not g.inventory[g.selected_item].get("kept",false);return true
	return false
func controls() -> void:
	g.button(Rect2(330,194,215,40),"Sort: "+["Level","Rarity","Name"][sort_mode],"inventory_sort")
	g.button(Rect2(555,194,220,40),["All","Equipped","Spares","Protected"][filter_mode],"inventory_filter")
