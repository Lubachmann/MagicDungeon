extends RefCounted
# Compatibility helpers for old saves containing standalone forge/altar screens.
# New runs craft directly from Equipment.
var g
func _init(game):g=game
func find_forge() -> Vector2i:
 for tile in g.rooms[g.room].entities:
  if g.rooms[g.room].entities[tile].kind=="salvage" and absi(tile.x-g.pos.x)+absi(tile.y-g.pos.y)<=1:return tile
 return Vector2i(-1,-1)
func used(kind: String) -> bool:
 if g.floor_flags.get("forge_"+kind+"_used",false):return true
 var legacy="rarity_altar" if kind=="rarity" else "runesmith"
 for room in g.rooms.values():
  for entity in room.entities.values():
   if entity.get("kind","")==legacy and entity.get("used",false):return true
 return false
func mark_used(kind: String) -> void:g.floor_flags["forge_"+kind+"_used"]=true
func open(tile: Vector2i) -> void:
 g.puzzle_tile=tile;g.open_equipment();g.run_metrics.erase("forge_tab")
func handle(id: String) -> bool:
 if id=="forge_open" and g.mode=="equipment":return true
 if g.mode=="decision" and g.rooms[g.room].entities.get(g.puzzle_tile,{}).get("kind","")=="salvage" and (id.begins_with("rarity_") or id=="decision_leave"):
  g.mode="equipment";g.run_metrics.erase("forge_tab");return true
 if g.mode=="forge":
  g.mode="equipment";g.run_metrics.erase("forge_tab")
  return id.begins_with("forge_")
 return false
func draw() -> void:g.draw_equipment()
