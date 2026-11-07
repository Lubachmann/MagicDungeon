extends RefCounted
const PER_PAGE=7
const Presenter=preload("res://equipment_presenter.gd")
var g
var page=0
func _init(game):g=game
func start() -> void:
 page=0
func draw() -> void:
 var item=g.inventory[g.last_loot_index];var color=g.Gear.COLORS[item.rarity]
 var worn={}
 if g.equipped.has(item.slot):worn=g.inventory[int(g.equipped[item.slot])]
 var before=Presenter.numbers(worn);var after=Presenter.numbers(item)
 var rows=Presenter.keys(before,after)
 if item.slot=="weapon":rows.insert(mini(2,rows.size()),"power")
 var pages=maxi(1,ceili(float(rows.size())/PER_PAGE));page=clampi(page,0,pages-1)
 var frame=Rect2(365,190,550,480)
 g.panel(frame);g.draw_rect(frame.grow(-5),color,false,2)
 g.text(Vector2(390,224),"EQUIPMENT FOUND",21,g.GOLD)
 g.gear_icon(item.slot,Vector2(390,240),68,color,item)
 var name_size=26
 while name_size>16 and g.text_face(name_size).get_string_size(item.name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x>380:name_size-=1
 g.text(Vector2(475,270),item.name,name_size,color)
 g.text(Vector2(475,299),"%s / Level %d"%[g.Gear.RARITIES[item.rarity],item.level],19,color)
 g.text(Vector2(390,331),"STAT",18,g.INK)
 g.text(Vector2(664,331),"WORN" if not worn.is_empty() else "EMPTY",18,g.INK)
 g.text(Vector2(787,331),"FOUND",18,g.GOLD)
 for i in range(mini(PER_PAGE,rows.size()-page*PER_PAGE)):
  var stat=rows[page*PER_PAGE+i];var at=Vector2(390,362+i*32)
  g.stat_ui.label(stat,at,23)
  g.text(at+Vector2(30,0),g.stat_ui.short_name(stat),19,g.INK)
  var old=float(before.get(stat,0));var new=float(after.get(stat,0))
  var better=new<old if stat in ["base_interval","item_interval"] else new>old
  g.text(at+Vector2(274,0),Presenter.value(stat,before),20,g.INK)
  g.text(at+Vector2(397,0),Presenter.value(stat,after),22,g.INK if is_equal_approx(old,new) else g.TEAL if better else Color("e88882"))
 if pages>1:
  g.button(Rect2(390,578,45,29),"<","loot_prev",false,page>0)
  g.text(Vector2(446,600),"Stats %d / %d"%[page+1,pages],17,g.INK)
  g.button(Rect2(558,578,45,29),">","loot_next",false,page<pages-1)
 var first_weapon=g.guided and g.guided.active() and int(g.run_metrics.get("guide_step",-1))==0 and item.slot=="weapon"
 if first_weapon:g.text(Vector2(625,594),"Equip your first weapon",17,g.GOLD)
 var equip_rect=Rect2(386,604,244,58);var keep_rect=Rect2(639,604,256,58)
 g.button(equip_rect,"","loot_equip")
 g.button(keep_rect,"","loot_keep")
 for entry in [[equip_rect,"[1] Equip"],[keep_rect,"[2] Keep in bag"]]:
  var rect:Rect2=entry[0];var label:String=entry[1];var size=23
  var width=g.text_face(size).get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
  g.text(Vector2(rect.get_center().x-width/2,rect.position.y+37),label,size,g.GOLD)
