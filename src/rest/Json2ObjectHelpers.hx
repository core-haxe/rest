package rest;

class Json2ObjectHelpers {
	public static function writeDate(v:Date):String {
		return v.getTime() + '';
	}

	public static function parseDate(val:hxjsonast.Json, name:String):Date {
		return switch (val.value) {
			case JString(s):
				Date.fromString(s);
			case JNumber(s):
				Date.fromTime(Std.parseFloat(s));
			default:
				null;

		}
	}
    
}