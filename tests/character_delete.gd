extends SceneTree
const BASE="/private/tmp/magicdungeon_character_delete_test"
var failures=[]
func check(v:bool,msg:String):
 if not v:failures.append(msg)
func clean():
 var d=DirAccess.open("/private/tmp");d.include_hidden=true
 for name in d.get_files():
  if name.begins_with("magicdungeon_character_delete_test"):d.remove(name)
func _initialize():call_deferred("run")
func run():
 clean();var g=load("res://main.tscn").instantiate();g.save_path=BASE;root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true
 g.mode="profiles";check(not g.profiles.delete_character(0),"Cannot delete last character")
 g.bank=73;g.skills={"kindling":1};g.save_progress();var original=FileAccess.get_file_as_bytes(BASE)
 for i in range(4):
  g.mode="profiles";check(g.profiles.create(),"Create character %d"%i)
 check(g.profiles.ids.size()==5,"Five characters allowed")
 g.mode="profiles";var current=g.profiles.current;check(not g.profiles.create() and g.profiles.current==current and g.profiles.ids.size()==5,"Sixth character blocked without changes")
 g.profiles.handle("profile_delete:0");check(g.profiles.pending_delete==0 and FileAccess.file_exists(BASE),"Delete request does not delete")
 g.profiles.handle("profile_delete_cancel");check(g.profiles.pending_delete==-1 and FileAccess.get_file_as_bytes(BASE)==original,"Cancel preserves progress")
 var current_path=g.save_path;g.bank=44;g.save_progress();var active_bytes=FileAccess.get_file_as_bytes(current_path);var settings=FileAccess.open(BASE+".settings",FileAccess.WRITE);settings.store_string("shared settings");settings.close()
 var blocker=FileAccess.open(BASE+".deleting",FileAccess.WRITE);blocker.store_string("existing staged data");blocker.close()
 g.profiles.handle("profile_delete:0");g.profiles.handle("profile_delete_confirm")
 check(0 in g.profiles.ids and FileAccess.get_file_as_bytes(BASE)==original,"Failed staging preserves original character")
 DirAccess.remove_absolute(BASE+".deleting")
 g.profiles.handle("profile_delete:0");g.profiles.handle("profile_delete_confirm")
 check(0 not in g.profiles.ids and not FileAccess.file_exists(BASE),"Deleting slot zero removes only its progress")
 check(FileAccess.get_file_as_bytes(current_path)==active_bytes and FileAccess.get_file_as_string(BASE+".settings")=="shared settings","Other character and shared settings unchanged")
 var removed=g.profiles.current;g.mode="profiles";g.profiles.handle("profile_delete:"+str(removed));g.profiles.handle("profile_delete_confirm")
 check(removed not in g.profiles.ids and g.profiles.current in g.profiles.ids and g.save_path!=current_path,"Deleting active character selects another")
 g.mode="profiles";var prior_next=g.profiles.next_id;check(g.profiles.create() and g.profiles.current>=prior_next and g.profiles.current!=removed,"New character never reuses deleted path")
 var count=g.profiles.ids.size();var active=g.save_path;g.bank=19;g.save_progress();var staged_bytes=FileAccess.get_file_as_bytes(active);DirAccess.rename_absolute(active,active+".deleting");g.save_path=BASE;var loaded=preload("res://character_profiles.gd").new(g);check(loaded.ids.size()==count and removed not in loaded.ids,"Deletion persists on restart");check(FileAccess.get_file_as_bytes(active)==staged_bytes,"Interrupted deletion is restored on startup")
 g.free();clean();print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
