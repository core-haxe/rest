package cases.api;

import rest.IMappableAuto;

@:structInit
class SearchProductRequest implements IMappableAuto {
    public var query:String;
}
