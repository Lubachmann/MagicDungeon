extends RefCounted
const Stats=preload("res://build_stats.gd")
static func preview(g) -> Dictionary:
 if not g.equipped.has("weapon"):return {}
 var index=int(g.equipped.weapon);var item=g.inventory[index].duplicate(true);item.level+=1
 var before=Stats.calculate(g);var after=Stats.prospective(g,index,{index:item})
 before["current_hp"]=g.hp;after.max_hp=maxi(20,after.max_hp-8);after["current_hp"]=mini(g.hp-8,after.max_hp)
 return {"index":index,"item":item,"before":before,"after":after}
static func draw(g) -> void:
 g.front_end.overlay(Rect2(100,65,1080,710));g.ui_icon("fire",Vector2(125,85),42);g.text(Vector2(185,117),"CINDER SHRINE",32,g.GOLD)
 g.draw_wrapped("Trade health for a stronger weapon, or take embers.",Vector2(125,161),340,21,g.INK,2)
 g.front_end.icon_button(Rect2(125,230,340,82),"attack","Weapon +1 level","shrine_temper",false,g.hp>8 and g.max_hp>28 and g.equipped.has("weapon"))
 g.stat_ui.icon("current_hp",Vector2(140,327),24,"Sacrifice health","Accepting costs 8 current HP and 8 maximum HP for the rest of this run. The preview includes both costs and the weapon's upgrade.")
 g.draw_wrapped("Cost: 8 current HP + 8 max HP",Vector2(180,348),280,20,g.INK,2)
 g.front_end.icon_button(Rect2(125,430,340,82),"ember","Take 4 embers","shrine_embers")
 g.front_end.icon_button(Rect2(125,570,340,66),"boots","Leave","shrine_leave")
 g.draw_wrapped("One choice. The health cost lasts this run.",Vector2(125,690),335,19,g.TEAL,2)
 var data=preview(g)
 if data.is_empty():g.text(Vector2(525,240),"Equip a weapon to preview tempering.",22,g.INK);return
 g.panel(Rect2(500,170,650,320));g.text(Vector2(525,207),"WEAPON / LV.%d → %d"%[data.item.level-1,data.item.level],24,g.GOLD)
 g.text(Vector2(860,235),"NOW",18);g.text(Vector2(1000,235),"AFTER",18,g.TEAL)
 preload("res://equipment_presenter.gd").draw_comparison(g,g.inventory[data.index],data.item,Vector2(525,266),600,175,true)
 g.panel(Rect2(500,515,650,220));g.text(Vector2(525,550),"BUILD IF ACCEPTED",23,g.GOLD)
 g.text(Vector2(830,578),"NOW",18);g.text(Vector2(985,578),"AFTER",18,g.TEAL)
 g.build_view.draw_compare(data.index,{data.index:data.item},Vector2(525,610),600,90,8)
