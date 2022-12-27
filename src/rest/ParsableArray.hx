package rest;

import haxe.Constraints.Constructible;

@:generic
class ParsableArray<TItem:Constructible<Void->Void> & IParsable> implements IParsable {
    private var _items:Array<TItem> = null;

    public function parse(response:Any) {
        _items = [];
        if ((response is Array)) {
            var items:Array<Any> = response;
            for (item in items) {
                var parsable = new TItem();
                parsable.parse(item);
                _items.push(item);
            }
        }
    }

    public var length(get, null):Int;
    private function get_length():Int {
        return _items.length;
    }

	public function iterator() {
        if (_items == null) {
            return null;
        }
        return _items.iterator();
    }
}
