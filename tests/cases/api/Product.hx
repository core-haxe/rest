package cases.api;

import rest.IJson2ObjectParsable;
import rest.IMappableAuto;

class Product implements IMappableAuto implements IJson2ObjectParsable {
    public var id:Int;
    public var title:String;
}
