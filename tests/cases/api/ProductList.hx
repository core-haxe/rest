package cases.api;

import rest.IJson2ObjectParsable;

class ProductList implements IJson2ObjectParsable {
    public var total:Int;
    public var skip:Int;
    public var limit:Int;
    public var products:Array<Product>;
}
