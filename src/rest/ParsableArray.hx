package rest;

import haxe.Constraints.Constructible;

using StringTools;

@:generic
class ParsableArray<TItem:Constructible<Void->Void> & IParsable> implements IParsable {
    public var items:Array<TItem> = null;

    public function parse(response:Any) {
        this.items = [];
        if ((response is String)) {
            var responseString:String = response;
            responseString = responseString.trim();
            if (responseString.startsWith("[") && responseString.endsWith("]")) {
                response = haxe.Json.parse(responseString);
            }
        }
        if ((response is Array)) {
            var items:Array<Any> = response;
            for (item in items) {
                var parsable = new TItem();
                parsable.parse(item);
                this.items.push(parsable);
            }
        }
    }

    public inline function item(index:Int):TItem {
        return items[index];
    }

    public var length(get, null):Int;
    private function get_length():Int {
        return items.length;
    }

	public function iterator() {
        if (items == null) {
            return null;
        }
        return items.iterator();
    }

    public function toArray():Array<TItem> {
        return items;
    }
}
