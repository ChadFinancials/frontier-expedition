class_name Inventory
extends RefCounted
## The wagon's cargo as Darkest Dungeon-style slots. Supplies stay a plain {item: count}
## dictionary; this works out how many slots that fills (each item stacks up to its
## `stack` size) and how much more fits. The wagon has `wagon_slots` slots (config).

const ORDER := ["food", "bandages", "antivenom", "whiskey", "lamp_oil", "wagon_parts", "rope", "shovel", "crowbar", "salt", "timber", "iron", "hides"]


## Extra slots for the expedition being planned or played (a Wheelwright at its home town;
## set by Company.set_wagon_for).
static var extra_slots := 0


static func capacity() -> int:
	return int(DB.cfg("wagon_slots", 12)) + extra_slots


static func stack_size(item: String) -> int:
	return maxi(1, int(DB.items.get(item, {}).get("stack", 1)))


static func slots_used(supplies: Dictionary) -> int:
	var n := 0
	for it in supplies:
		var c := int(supplies[it])
		if c > 0:
			n += int(ceil(c / float(stack_size(it))))
	return n


## How many more of `item` fit without going over the wagon's slots.
static func room_for(supplies: Dictionary, item: String, cap: int = -1) -> int:
	var slots := capacity() if cap < 0 else cap
	var c := int(supplies.get(item, 0))
	var st := stack_size(item)
	var partial := (st - c % st) % st if c > 0 else 0
	var free := maxi(0, slots - slots_used(supplies))
	return partial + free * st


## The slots in display order: [{item, count}], one entry per (partial) stack.
static func stacks(supplies: Dictionary) -> Array:
	var out: Array = []
	var items: Array = ORDER.duplicate()
	for it in supplies:
		if not it in items:
			items.append(it)
	for it in items:
		var c := int(supplies.get(it, 0))
		var st := stack_size(it)
		while c > 0:
			out.append({"item": it, "count": mini(c, st)})
			c -= st
	return out
