extends RefCounted
## Exact paid ledger prevents inflation when prices or caps change.
const BRANCHES=["Vitality","Arsenal","Fortune","Runes"]
const NODES={
	"kindling":{"name": "Kindling", "branch": -1, "parent": "", "icon": "ember", "costs": [8], "effect": "+4 max HP. Unlocks all 4 skill branches.", "cell": Vector2i(0,0)},
	"vigor":{"name": "Vigor", "branch": 0, "parent": "kindling", "icon": "health", "costs": [16, 23, 31, 40, 49, 61, 73, 86, 100, 116, 133, 150, 169, 189, 210], "effect": "+3 max HP per rank.", "cell": Vector2i(0,0)},
	"armor_training":{"name": "Fortitude", "branch": 0, "parent": "vigor", "icon": "armor", "costs": [30, 41, 53, 67, 83, 102, 122, 145, 170, 197, 225, 257], "effect": "+0.6 armor per rank.", "cell": Vector2i(1,0)},
	"flaskcraft":{"name": "Flaskcraft", "branch": 0, "parent": "vigor", "icon": "potion", "costs": [100, 240, 480], "effect": "Flasks heal 33 / 37 / 41 HP at ranks 1 / 2 / 3.", "cell": Vector2i(0,1)},
	"wellkeeper":{"name": "Wellkeeper", "branch": 0, "parent": "flaskcraft", "icon": "potion", "costs": [60, 93, 129, 169, 214], "effect": "+3 HP healed by fountains per rank.", "cell": Vector2i(1,1)},
	"flask_reserve":{"name": "Reserves", "branch": 0, "parent": "flaskcraft", "icon": "potion", "costs": [260, 600, 1100], "effect": "+1 flask at the start of each run per rank.", "cell": Vector2i(0,2)},
	"field_medicine":{"name": "Rekindle", "branch": 0, "parent": "wellkeeper", "icon": "health", "costs": [80, 118, 162, 211, 265], "effect": "+2 HP restored by each healing flask per rank.", "cell": Vector2i(1,2)},
	"recovery":{"name": "Renewal", "branch": 0, "parent": "armor_training", "icon": "health", "costs": [400, 1000], "effect": "+1 HP healed after each victory per rank.", "cell": Vector2i(0,3)},
	"second_wind":{"name": "Second Wind", "branch": 0, "parent": "flask_reserve", "icon": "sun", "costs": [1800], "effect": "Survive death once per run. Return with 25% max HP.", "cell": Vector2i(1,3)},
	"might":{"name": "Might", "branch": 1, "parent": "kindling", "icon": "attack", "costs": [20, 29, 39, 51, 64, 78, 94, 111, 129, 149, 171, 193, 217, 243, 270], "effect": "+0.7 character attack per rank. Weapons scale this hit power.", "cell": Vector2i(0,0)},
	"tempo":{"name": "Tempo", "branch": 1, "parent": "might", "icon": "speed", "costs": [40, 57, 76, 98, 123, 151, 181, 214, 250, 289], "effect": "+1% attack speed per rank.", "cell": Vector2i(1,0)},
	"precision_training":{"name": "Precision", "branch": 1, "parent": "tempo", "icon": "crit", "costs": [45, 65, 88, 114, 143, 175, 210, 249, 290, 335], "effect": "+1% critical chance per rank.", "cell": Vector2i(0,1)},
	"ruin_training":{"name": "Ruin", "branch": 1, "parent": "precision_training", "icon": "crit_damage", "costs": [50, 72, 98, 126, 159, 194, 234, 276, 323, 372], "effect": "+3% critical damage per rank.", "cell": Vector2i(1,1)},
	"tinkering":{"name": "Tinkering", "branch": 1, "parent": "might", "icon": "iron", "costs": [75], "effect": "+1 ore from the first iron pickup each floor.", "cell": Vector2i(0,2)},
	"runeforge":{"name": "Rune Forge", "branch": 1, "parent": "tinkering", "icon": "fire", "costs": [180], "effect": "Reduce the ore cost of smithy rune infusions by 1, to a minimum of 1. Find elemental rune blueprints in elemental passages.", "cell": Vector2i(1,2)},
	"smithcraft":{"name": "Quartermaster", "branch": 1, "parent": "runeforge", "icon": "hammer", "costs": [220, 550, 1050], "effect": "+1 bonus ore per rank from the first deposit mined each expedition.", "cell": Vector2i(0,3)},
	"salvage_master":{"name": "Scrapper", "branch": 1, "parent": "runeforge", "icon": "salvage", "costs": [160, 360, 760], "effect": "+1 ore from mining deposits per rank.", "cell": Vector2i(1,3)},
	"cartography":{"name": "Cartography", "branch": 2, "parent": "kindling", "icon": "map", "costs": [40], "effect": "Show the room types next to rooms you have visited.", "cell": Vector2i(0,0)},
	"treasure_hunter":{"name": "Prospector", "branch": 2, "parent": "cartography", "icon": "key", "costs": [35, 49, 64, 83, 103, 126, 152, 180, 210, 243], "effect": "+3% chance per rank for chests to yield 2 extra ore.", "cell": Vector2i(1,0)},
	"runic_sight":{"name": "Runic Sight", "branch": 2, "parent": "cartography", "icon": "vault", "costs": [180], "effect": "Show the first puzzle symbol and gain 3 ore when claiming a reliquary reward.", "cell": Vector2i(0,1)},
	"gilded_touch":{"name": "Gilded Touch", "branch": 2, "parent": "treasure_hunter", "icon": "sun", "costs": [70, 97, 128, 165, 206, 252, 303, 359, 419, 485], "effect": "+2% chance per rank for chests to yield an extra Warden core.", "cell": Vector2i(1,1)},
	"recall":{"name": "Recall", "branch": 2, "parent": "runic_sight", "icon": "boots", "costs": [300], "effect": "Return to the floor entrance once per floor. Cannot be used in combat.", "cell": Vector2i(0,2)},
	"embercraft":{"name": "Embercraft", "branch": 2, "parent": "cartography", "icon": "ember", "costs": [25, 36, 49, 63, 80, 97, 117, 138, 162, 186], "effect": "+2% embers kept at the end of a run per rank.", "cell": Vector2i(1,2)},
	"relic_lens":{"name": "Relic Lens", "branch": 2, "parent": "runic_sight", "icon": "relic", "costs": [160, 420, 900], "effect": "+1 upgrade reroll per floor per rank.", "cell": Vector2i(0,3)},
	"supply_cache":{"name": "Forager", "branch": 2, "parent": "embercraft", "icon": "potion", "costs": [70, 103, 140, 183, 230], "effect": "+2% chance for each defeated enemy to drop a flask per rank.", "cell": Vector2i(1,3)},
	"fire_mastery":{"name": "Pyromancy", "branch": 3, "parent": "kindling", "icon": "fire", "costs": [40, 56, 74, 95, 119, 146, 175, 207, 242, 280], "effect": "+5% fire damage per rank. Requires fire on your build.", "cell": Vector2i(0,0)},
	"ice_mastery":{"name": "Cryomancy", "branch": 3, "parent": "kindling", "icon": "ice", "costs": [40, 56, 74, 95, 119, 146, 175, 207, 242, 280], "effect": "+5% Frost stacks per hit per rank. Requires Frost on your build.", "cell": Vector2i(1,0)},
	"acid_mastery":{"name": "Alchemy", "branch": 3, "parent": "kindling", "icon": "acid", "costs": [40, 56, 74, 95, 119, 146, 175, 207, 242, 280], "effect": "+5% more armor removed by acid per rank. Does not add acid to your attacks.", "cell": Vector2i(0,1)},
	"poison_mastery":{"name": "Venomcraft", "branch": 3, "parent": "kindling", "icon": "poison", "costs": [40, 56, 74, 95, 119, 146, 175, 207, 242, 280], "effect": "+5% Poison stacks per hit per rank. Requires Poison on your build.", "cell": Vector2i(1,1)},
	"insight":{"name": "Insight", "branch": 3, "parent": "kindling", "icon": "book", "costs": [350], "effect": "Choose from 4 level-up upgrades instead of 3.", "cell": Vector2i(0,2)},
	"transmutation":{"name": "Fortune", "branch": 3, "parent": "kindling", "icon": "relic", "costs": [260], "effect": "+10% chance for a Rare skill in each level-up choice, when available.", "cell": Vector2i(1,2)},
	"convergence":{"name": "Convergence", "branch": 3, "parent": "insight", "icon": "relic", "costs": [500], "effect": "+10% chance for an Epic skill in each level-up choice, when available.", "cell": Vector2i(0,3)},
	"blastcraft":{"name": "Iron Cache", "branch": 3, "parent": "poison_mastery", "icon": "iron", "costs": [140, 360, 780], "effect": "+1 bonus ore per rank from the first deposit mined each expedition.", "cell": Vector2i(1,3)},
}
const OLD_COSTS={"kindling":[4],"vigor":[6,10,14],"cartography":[6],"tinkering":[6],"flaskcraft":[12],"runic_sight":[14],"relic_lens":[14],"second_wind":[30],"recall":[18],"runeforge":[22]}
var g
var branch=0
var selected="kindling"
var return_mode="title"
var reset_pending=false
func _init(game):g=game
static func legacy_refund(ranks: Array) -> int:
	var total=0
	for value in ranks:
		var rank=clampi(int(value),0,5)
		total+=3*rank*rank+5*rank
	return total
static func clean(value) -> Dictionary:
	var result={}
	if value is Dictionary:
		for id in NODES:result[id]=clampi(int(value.get(id,0)),0,NODES[id].costs.size())
	return result
func rank(id: String,during_run: bool=true) -> int:
	return int((g.run_skills if during_run else g.skills).get(id,0))
func health_bonus() -> int:return 4*rank("kindling")+(3 if g.run_rules>=5 else 4)*rank("vigor")
func price(id: String) -> int:
	var level=rank(id,false)
	return -1 if level>=NODES[id].costs.size() else NODES[id].costs[level]
func available(id: String) -> bool:
	var parent=NODES[id].parent
	return parent=="" or rank(parent,false)>0
static func old_spent(value: Dictionary) -> int:
	var total=0
	for id in OLD_COSTS:
		for i in range(clampi(int(value.get(id,0)),0,OLD_COSTS[id].size())):total+=OLD_COSTS[id][i]
	return total
func spent() -> int:return g.tree_spent
func buy(id: String) -> bool:
	if g.mode!="skills" or not NODES.has(id):return false
	var cost=price(id)
	if cost<0 or not available(id) or g.bank<cost:return false
	var old=g.skills.duplicate()
	g.bank-=cost;g.tree_spent+=cost;g.skills[id]=rank(id,false)+1
	if not g.session.commit_profile():g.bank+=cost;g.tree_spent-=cost;g.skills=old;return false
	g.sfx("blessing")
	return true
func reset() -> bool:
	if g.mode!="skills":return false
	var refund=spent();var old=g.skills.duplicate()
	g.bank+=refund;g.skills={};g.tree_spent=0
	if not g.session.commit_profile():g.bank-=refund;g.skills=old;g.tree_spent=refund;return false
	return true
func visible_role(coord: Vector2i) -> bool:
	if g.visited.has(coord):return true
	if rank("cartography")==0:return false
	for neighbor in g.links[coord]:
		if g.visited.has(neighbor):return true
	return false
func node_rect(id: String) -> Rect2:
	if id=="kindling":return Rect2(70,195,140,112)
	var cell=NODES[id].cell
	return Rect2(270+cell.x*315,195+cell.y*132,266,108)

func connection_path(id: String) -> PackedVector2Array:
	# One selected dependency, routed through card gutters. No diagonal crossings.
	var parent=NODES[id].parent
	if parent=="":return PackedVector2Array()
	var source=node_rect(parent);var target=node_rect(id)
	var gutter=target.position.y-12
	var lane=235.0 if parent=="kindling" else (248.0 if NODES[parent].cell.x==0 else 875.0)
	var start=Vector2(source.end.x,source.get_center().y) if parent=="kindling" or NODES[parent].cell.x==1 else Vector2(source.position.x,source.get_center().y)
	return PackedVector2Array([start,Vector2(lane,start.y),Vector2(lane,gutter),Vector2(target.get_center().x,gutter),Vector2(target.get_center().x,target.position.y)])

func draw() -> void:
	if reset_pending:
		g.front_end.menu_backdrop();g.front_end.overlay(Rect2(280,250,720,340))
		g.text(Vector2(325,310),"RESET THE EMBER TREE?",28,g.GOLD)
		g.draw_wrapped("Refund %d embers and remove all learned ranks. Changes apply to future expeditions."%spent(),Vector2(325,365),630,21,g.INK,3)
		g.button(Rect2(325,475,290,60),"Reset / +%d"%spent(),"skills_reset_confirm")
		g.button(Rect2(645,475,290,60),"Cancel","skills_reset_cancel");return
	g.front_end.menu_backdrop()
	g.text(Vector2(70,80),"EMBER TREE",36,g.GOLD)
	g.ui_icon("ember",Vector2(965,45),32);g.text(Vector2(1008,77),str(g.bank),28,g.GOLD)
	for i in range(4):
		g.front_end.icon_button(Rect2(70+i*222,110,208,58),["health","attack","key","fire"][i],BRANCHES[i],"tree_tab:%d"%i,branch==i)
	var root_rect=Rect2(70,195,140,112)
	g.button(root_rect,"","skill_select:kindling",selected=="kindling")
	g.ui_icon("ember",Vector2(119,208),32)
	g.text(Vector2(87,268),"Kindling",20,g.GOLD)
	g.text(Vector2(100,292),"%d/1"%rank("kindling",false),16)
	var parent_id=NODES[selected].parent
	var ancestor=selected
	while NODES[ancestor].parent!="" and NODES[ancestor].branch==branch:
		var path=connection_path(ancestor);g.draw_polyline(path,g.TEAL,2)
		var tip=path[path.size()-1]
		g.draw_polyline(PackedVector2Array([tip+Vector2(-5,-7),tip,tip+Vector2(5,-7)]),g.TEAL,2)
		ancestor=NODES[ancestor].parent
	if ancestor=="kindling" and selected!="kindling":g.draw_rect(root_rect.grow(3),g.TEAL,false,2)
	for id in NODES:
		var node=NODES[id]
		if node.branch!=branch:continue
		var at=Vector2(270+node.cell.x*315,195+node.cell.y*132)
		g.button(Rect2(at,Vector2(266,108)),"","skill_select:"+id,selected==id)
		if id==parent_id:g.draw_rect(Rect2(at,Vector2(266,108)).grow(3),g.TEAL,false,2)
		g.ui_icon(node.icon,at+Vector2(16,17),32)
		g.text(at+Vector2(62,35),node.name,21,g.GOLD if available(id) or rank(id,false)>0 else Color("89828b"))
		g.text(at+Vector2(62,64),"%d / %d"%[rank(id,false),node.costs.size()],18,g.TEAL)
		g.ui_icon("ember",at+Vector2(18,77),16)
		g.text(at+Vector2(44,94),"MAX" if price(id)<0 else str(price(id)),18)
	var node=NODES[selected]
	g.panel(Rect2(925,195,285,510))
	g.ui_icon(node.icon,Vector2(1028,220),64)
	g.text(Vector2(947,325),node.name,26,g.GOLD)
	var description=describe(selected)
	g.draw_wrapped("Rank %d → %d. "%[rank(selected,false),mini(rank(selected,false)+1,node.costs.size())]+description,Vector2(947,369),240,20,g.INK,7)
	var status="MAXIMUM RANK" if price(selected)<0 else "Needs "+NODES[node.parent].name if not available(selected) and node.parent!="" else "Need %d more embers"%(price(selected)-g.bank) if g.bank<price(selected) else "Ready to learn"
	g.text(Vector2(947,574),status,16,g.TEAL)
	g.button(Rect2(947,615,240,58),"MAX" if price(selected)<0 else "Learn / %d"%price(selected),"skill_buy",false,price(selected)>=0 and available(selected) and g.bank>=price(selected))
	g.front_end.icon_button(Rect2(70,750,170,48),"boots","Back","skills_back")
	g.front_end.icon_button(Rect2(270,750,340,48),"ember","Reset / +%d"%spent(),"skills_reset",false,spent()>0)
	g.text(Vector2(705,781),"Changes apply to new runs",18,g.TEAL)
	g.text(Vector2(270,727),"Select a skill to trace its prerequisite",16,g.TEAL)
	if g.session.error!="":g.draw_wrapped(g.session.error,Vector2(70,730),1000,16,Color("ee9b88"),1)

func describe(id: String) -> String:
	var level=rank(id,false);var next=mini(NODES[id].costs.size(),level+1)
	# The values below match the current run rules and show the actual cumulative bonus.
	var linear={"vigor":[3.0,"max HP"],"armor_training":[0.6,"armor"],"might":[0.7,"character attack"],"precision_training":[1.0,"% crit chance"],"wellkeeper":[3.0,"HP from fountains"],"field_medicine":[2.0,"HP per flask"],"recovery":[1.0,"HP after victory"],"flask_reserve":[1.0,"starting flasks"],"salvage_master":[1.0,"ore per deposit"],"smithcraft":[1.0,"ore at first deposit"],"blastcraft":[1.0,"ore at first deposit"],"embercraft":[2.0,"% embers kept"],"supply_cache":[2.0,"% flask drop chance"],"relic_lens":[1.0,"rerolls per floor"],"fire_mastery":[5.0,"% fire damage"],"acid_mastery":[5.0,"% acid effect"],"ice_mastery":[5.0,"% frost effect"],"poison_mastery":[5.0,"% poison effect"],"kindling":[4.0,"max HP"],"transmutation":[10.0,"% rare offer chance"],"convergence":[10.0,"% epic offer chance"]}
	if id in linear:
		var stat=linear[id];var old_value=float(stat[0])*level;var new_value=float(stat[0])*next
		return "+%.1f → +%.1f %s. %s"%[old_value,new_value,stat[1],NODES[id].effect]
	if id=="flaskcraft":
		var old_value=25 if level==0 else 33+4*(level-1);var new_value=25 if next==0 else 33+4*(next-1)
		return "Flask base healing: %d → %d HP. Field Medicine adds to this."%[old_value,new_value]
	if id in ["treasure_hunter","gilded_touch"]:
		var step=3 if id=="treasure_hunter" else 2
		return "%d%% → %d%% chance. %s"%[step*level,step*next,NODES[id].effect]
	if id=="tempo":return "Attack speed bonus: +%d%% → +%d%%. The weapon and equipment determine the final attack interval."%[level,next]

	if id=="ruin_training":return "Critical hit damage: %.0f%% → %.0f%% of a normal hit next rank. +3%% per rank, before gear bonuses."%[150.0+3*level,150.0+3*next]
	if g.run_rules>=9 and id in ["ice_mastery","poison_mastery"]:return "+5% counters applied per hit per rank. Combines with elemental gear and run upgrades. Requires the element on your build."
	if id in ["ice_mastery","poison_mastery"]:
		var effect="slower enemy attacks" if id=="ice_mastery" else "less enemy damage"
		return "1 %s stack: %.1f%% → %.1f%% %s next rank. +5%% stronger effect per rank. Does not add %s. Max 65%%."%["Ice" if id=="ice_mastery" else "Poison",18*(1+0.05*level),18*(1+0.05*next),effect,"Ice" if id=="ice_mastery" else "Poison"]
	if NODES[id].costs.size()==1:return ("Unlocked. " if level>0 else "Not learned → unlocked. ")+NODES[id].effect
	return NODES[id].effect
