extends RefCounted
## Slot zero retains the original save path. New heroes never overwrite it.
const MAX_CHARACTERS=5
var g
var base_path=""
var current=0
var ids=[0]
var page=0
var next_id=1
var pending_delete=-1
var message=""
func _init(game):
	g=game;base_path=g.save_path
	for suffix in [".characters",".characters.bak"]:
		if not FileAccess.file_exists(base_path+suffix):continue
		var data=JSON.parse_string(FileAccess.get_file_as_string(base_path+suffix))
		if not data is Dictionary or not data.get("ids") is Array:continue
		var valid_ids=[]
		for value in data.ids:
			if (value is int or value is float) and int(value)>=0 and int(value) not in valid_ids:valid_ids.append(int(value))
		if valid_ids.is_empty() or not valid_ids.has(int(data.get("current",0))):continue
		ids=valid_ids;current=int(data.current);next_id=maxi(int(data.get("next_id",0)),int(ids.max())+1);break
	# Recover interrupted deletion before opening any registered character.
	for id in ids:
		for suffix in ["", ".tmp", ".run", ".run.tmp", ".run.bak"]:
			var path=slot_path(id)+suffix;var staged=path+".deleting"
			if FileAccess.file_exists(staged) and not FileAccess.file_exists(path):DirAccess.rename_absolute(staged,path)
	g.save_path=slot_path(current)
func slot_path(id: int) -> String:return base_path if id==0 else base_path+".hero-%d"%id
func name_of(id: int) -> String:return "Wanderer %d"%(id+1)
func persist() -> bool:
	var target=base_path+".characters"
	var file=FileAccess.open(target+".tmp",FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify({"version":1,"current":current,"ids":ids,"next_id":next_id}));file.flush();var status=file.get_error();file.close()
	if status!=OK:return false
	if FileAccess.file_exists(target) and DirAccess.copy_absolute(target,target+".bak")!=OK:return false
	return DirAccess.rename_absolute(target+".tmp",target)==OK
func select(id: int) -> bool:
	if g.mode!="profiles" or id not in ids:return false
	var old=current;current=id
	if not persist():current=old;g.session.error="Could not save character selection.";return false
	g.save_path=slot_path(id);g.session.cached={};g.session.active=false
	g.load_progress();g.new_run();g.session.boot();g.replay.reset_draft();return true
func create() -> bool:
	if g.mode!="profiles":return false
	if ids.size()>=MAX_CHARACTERS:message="Character limit reached. Delete a character to make room.";return false
	var id=maxi(next_id,int(ids.max())+1)
	# Never reuse a path, even if a recoverable registry was missing its latest entry.
	while FileAccess.file_exists(slot_path(id)) or FileAccess.file_exists(slot_path(id)+".run"):id+=1
	ids.append(id);var old_next=next_id;next_id=id+1
	if not select(id):ids.erase(id);next_id=old_next;message="Could not create character.";return false
	return true
func delete_character(id: int) -> bool:
	if g.mode!="profiles" or id not in ids or ids.size()<=1:return false
	# Switch first so no in-memory state can later write back to the deleted slot.
	if id==current:
		var replacement=-1
		for other in ids:
			if other!=id:replacement=other;break
		if not select(replacement):message="Could not switch characters; nothing was deleted.";return false
		g.mode="profiles"
	var slot=slot_path(id);var moved=[]
	# Stage only this slot's progress and run files; shared settings and registry stay untouched.
	for suffix in ["", ".tmp", ".run", ".run.tmp", ".run.bak"]:
		var path=slot+suffix
		if not FileAccess.file_exists(path):continue
		var staged=path+".deleting"
		if FileAccess.file_exists(staged) or DirAccess.rename_absolute(path,staged)!=OK:
			for entry in moved:DirAccess.rename_absolute(entry[1],entry[0])
			message="Could not delete character files; no progress was removed.";return false
		moved.append([path,staged])
	var previous=ids.duplicate();ids.erase(id)
	if not persist():
		ids=previous
		for entry in moved:DirAccess.rename_absolute(entry[1],entry[0])
		message="Could not update the character list; no progress was removed.";return false
	# Keep registry recovery from resurrecting a deleted slot after a damaged primary file.
	DirAccess.copy_absolute(base_path+".characters",base_path+".characters.bak")
	var cleanup_ok=true
	for entry in moved:
		if DirAccess.remove_absolute(entry[1])!=OK:cleanup_ok=false
	page=clampi(page,0,maxi(0,int((ids.size()-1)/3)))
	message=("Character deleted." if cleanup_ok else "Character removed, but some staged save files could not be deleted.")
	return cleanup_ok
func handle(id: String) -> bool:
	if id=="profiles" and g.mode=="title":g.mode="profiles";page=0;pending_delete=-1;message="";return true
	if g.mode!="profiles":return false
	if pending_delete>=0:
		if id=="profile_delete_cancel":pending_delete=-1
		elif id=="profile_delete_confirm":
			var target=pending_delete;pending_delete=-1;delete_character(target)
		return true
	if id=="profile_new":create();return true
	if id.begins_with("profile_delete:"):
		var target=int(id.get_slice(":",1))
		if target in ids and ids.size()>1:pending_delete=target;message=""
		else:message="Keep at least one character. Create another before deleting this one."
		return true
	if id.begins_with("profile:"):select(int(id.get_slice(":",1)));return true
	if id=="profile_next":page=mini(page+1,int((ids.size()-1)/3));return true
	if id=="profile_prev":page=maxi(0,page-1);return true
	if id=="profiles_back":g.mode="title";return true
	return false
func draw() -> void:
	g.front_end.menu_backdrop();g.text(Vector2(85,92),"CHARACTERS  %d / %d"%[ids.size(),MAX_CHARACTERS],36,g.GOLD)
	if pending_delete>=0:
		g.panel(Rect2(240,220,800,380));g.text(Vector2(280,275),"DELETE "+name_of(pending_delete).to_upper()+"?",31,g.GOLD)
		g.draw_wrapped("This permanently deletes this character's Ember Tree, embers, unlocks and saved run.",Vector2(280,330),720,24,g.INK,3)
		g.button(Rect2(280,475,320,65),"Cancel","profile_delete_cancel")
		g.button(Rect2(680,475,320,65),"Delete character","profile_delete_confirm")
		return
	g.front_end.icon_button(Rect2(870,46,325,62),"health","New character" if ids.size()<MAX_CHARACTERS else "Limit reached","profile_new",false,ids.size()<MAX_CHARACTERS)
	for row in range(3):
		var index=page*3+row
		if index>=ids.size():break
		var id=ids[index];var at=Vector2(85,155+row*170)
		g.button(Rect2(at,Vector2(900,140)),"","profile:%d"%id,id==current)
		g.button(Rect2(at+Vector2(920,40),Vector2(190,60)),"Delete","profile_delete:%d"%id,false,ids.size()>1)
		g.draw_texture_rect(g.textures.player,Rect2(at+Vector2(18,20),Vector2(96,96)),false)
		g.text(at+Vector2(145,47),name_of(id),28,g.GOLD)
		var data={}
		if FileAccess.file_exists(slot_path(id)):
			var parsed=JSON.parse_string(FileAccess.get_file_as_string(slot_path(id)))
			if parsed is Dictionary:data=parsed
		if id==current:data={"bank":g.bank,"skills":g.skills,"career":g.career}
		g.ui_icon("ember",at+Vector2(145,75),32);g.text(at+Vector2(190,102),str(int(data.get("bank",0))),25)
		g.ui_icon("relic",at+Vector2(370,75),32);g.text(at+Vector2(415,102),str(data.get("skills",{}).values().reduce(func(total,value):return total+int(value),0)),25)
		g.ui_icon("sun",at+Vector2(590,75),32);g.text(at+Vector2(635,102),str(data.get("career",{}).get("wins",0)),25)
		g.text(at+Vector2(750,80),"ACTIVE" if id==current else "Select",20,g.TEAL)
	g.front_end.icon_button(Rect2(85,720,180,58),"boots","Back","profiles_back")
	g.front_end.icon_button(Rect2(650,720,250,58),"map","Previous","profile_prev",false,page>0)
	g.front_end.icon_button(Rect2(925,720,270,58),"map","Next","profile_next",false,(page+1)*3<ids.size())
	g.text(Vector2(85,690),message if message!="" else "Up to 5 characters. Keep at least one character.",19,g.TEAL)
