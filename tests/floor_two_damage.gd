extends SceneTree
const Pacing=preload("res://combat_pacing.gd")
var failures=[]
func check(ok: bool,message: String):
 if not ok:failures.append(message)
func _initialize():
 for floor_number in [1,2,3,5]:
  for kind in [0,1,2,3]:
   for tier in [1,3,6]:
    var level=1+6*(floor_number-1)+tier-1
    var original={"type":kind,"level":level,"boss_kind":"iron"};var updated=original.duplicate(true)
    Pacing.enemy(original,floor_number,1,19);Pacing.enemy(updated,floor_number,1,20)
    check(is_equal_approx(updated.attack,float(original.attack)*(0.85 if floor_number==2 else 1.0)),"Floor %d type %d tier %d damage"%[floor_number,kind,tier])
    check(updated.hp==original.hp and is_equal_approx(updated.armor,original.armor) and is_equal_approx(updated.speed,original.speed),"Other enemy stats remain unchanged")
 print(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
