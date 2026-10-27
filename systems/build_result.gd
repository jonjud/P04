extends RefCounted
class_name BuildResult
# {ok, reason, done} ตัดสินว่ามีการเปลี่ยน state จาก done > 0 เท่านั้น
# check() (dry-run) คืน ok=true แต่ done=0 เพราะยังไม่แก้อะไร
#the uses is like OpResult , collection of Result as StringName

const OK : StringName = &"ok"
const NULL_DB : StringName = &"null_db"
const NULL_INVENTORY : StringName = &"null_inventory"
const UNKNOWN_PIECE : StringName = &"unknown_piece"
const BAD_ROTATION : StringName = &"bad_rotation"
const CANNOT_ROTATE : StringName = &"cannot_rotate"
const OUT_OF_BOUNDS : StringName = &"out_of_bounds"
const OVERLAP : StringName = &"overlap"
const NOT_ENOUGH : StringName = &"not_enough_quantity"
const NO_STRUCTURE : StringName = &"no_structure"
const CHEST_NOT_EMPTY : StringName = &"chest_not_empty"
const INVENTORY_FULL : StringName = &"inventory_full"
const INTERNAL : StringName = &"internal"
# from_dict
const INCOMPLETE_DATA : StringName = &"incomplete_data"
const BAD_SCHEMA : StringName = &"bad_schema"
const BAD_DATA : StringName = &"bad_data"

static func make(reason : StringName, done : int) -> Dictionary:
	return {"ok": reason == OK, "reason": reason, "done": done}
