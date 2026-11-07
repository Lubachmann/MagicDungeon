extends RefCounted
## Authored formations are placed whole; routes through gates remain intact.
const NAMES=["Pillar court","Broken shelves","Twin barricades","Side galleries"]
const GROUPS=[
	[[Vector2i(-3,-2),Vector2i(-2,-2)],[Vector2i(2,-2),Vector2i(3,-2)],[Vector2i(-3,2),Vector2i(-2,2)],[Vector2i(2,2),Vector2i(3,2)],[Vector2i(-4,-3),Vector2i(-4,-2)],[Vector2i(4,2),Vector2i(4,3)]],
	[[Vector2i(-4,-2),Vector2i(-3,-2),Vector2i(-2,-2)],[Vector2i(2,2),Vector2i(3,2),Vector2i(4,2)],[Vector2i(2,-3),Vector2i(3,-3)],[Vector2i(-3,3),Vector2i(-2,3)]],
	[[Vector2i(-2,-3),Vector2i(-2,-2),Vector2i(-2,-1)],[Vector2i(2,1),Vector2i(2,2),Vector2i(2,3)],[Vector2i(3,-2),Vector2i(4,-2)],[Vector2i(-4,2),Vector2i(-3,2)]],
	[[Vector2i(-4,-3),Vector2i(-3,-3),Vector2i(-3,-2)],[Vector2i(3,2),Vector2i(3,3),Vector2i(4,3)],[Vector2i(-3,2),Vector2i(-3,3)],[Vector2i(3,-3),Vector2i(3,-2)]]]
static func unlocked(data: Dictionary) -> Dictionary:
	var seen={Vector2i(6,5):true};var queue=[Vector2i(6,5)]
	while not queue.is_empty():
		var p=queue.pop_front()
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q=p+d
			if not data.bounds.grow(-1).has_point(q) or seen.has(q):continue
			if data.walls.has(q) and data.entities.get(q,{}).get("kind","")!="crack":continue
			seen[q]=true;queue.append(q)
	return seen
static func place_group(g,data: Dictionary,group: Array,reserved: Array) -> int:
	var tiles=[]
	for offset in group:
		var p=Vector2i(6,5)+offset
		if not data.bounds.grow(-1).has_point(p) or p.x==6 or p.y==5 or p in reserved or data.entities.has(p) or data.walls.has(p) or p.distance_to(Vector2i(2,5))<2:return 0
		tiles.append(p)
	var before=g.dungeon_threads.reachable(data);var future=unlocked(data)
	for p in tiles:data.walls[p]=true
	var after=g.dungeon_threads.reachable(data);var later=unlocked(data);var safe=true
	for p in before:
		if p not in tiles and not after.has(p):safe=false;break
	if safe:
		for p in future:
			if p not in tiles and not later.has(p):safe=false;break
	if not safe:
		for p in tiles:data.walls.erase(p)
		return 0
	return tiles.size()
static func fill(g) -> void:
	if g.run_rules<6:return
	for coord in g.rooms:
		if coord==g.boss_room:continue
		var data=g.rooms[coord];var bounds: Rect2i=data.bounds
		var reserved=data.get("chest_path",[]).duplicate();reserved.append(data.get("chest_approach",Vector2i(-1,-1)));reserved.append(data.special)
		var rolled=g.rng.randi_range(0,GROUPS.size()-1)
		var index={"Fountain":3,"Forge":3,"Elite":2,"Armory":1,"Hammer":0,"Boots":0}.get(g.roles[coord],rolled);data["formation"]=NAMES[index]
		var added=0
		for group in GROUPS[index]:added+=place_group(g,data,group,reserved)
		# Authored single-pillar anchors fill smaller rooms where large groups do not fit.
		for offset in [Vector2i(-2,-1),Vector2i(2,1),Vector2i(-1,2),Vector2i(1,-2),Vector2i(-3,1),Vector2i(3,-1)]:
			if added>=8:break
			added+=place_group(g,data,[offset],reserved)
		data["added_walls"]=added
		if coord!=Vector2i.ZERO and g.roles[coord]!="Fountain":
			var e=g.make_enemy(0,int(g.distances[coord]));if g.run_rules<15:e.hp=ceilf(e.hp*0.75);e.max=e.hp;e.attack=maxf(1,roundf(e.attack*0.85))
			e["room_extra"]=true;g.dungeon_threads.place(coord,e)
		for i in range(1 if bounds.size.x<=9 else 2):g.dungeon_threads.place(coord,{"kind":"urn","contents":g.rng.randi_range(0,3)})
