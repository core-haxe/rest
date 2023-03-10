package rest;

import haxe.http.HttpMethod;
import http.HttpMethod;

class RestRequest {
    public var verb:HttpMethod = HttpMethod.Get;
    public var path:String;
    public var urlParams:Map<String, Any>;
    public var queryParams:Map<String, Any>;
    public var headers:Map<String, Any>;
    public var body:Any;
    public var useAlternateConfig:Bool = false;

    public function new() {
    }

    public function addHeader(name:String, value:Any) {
        if (headers == null) {
            headers = [];
        }
        headers.set(name, value);
    }

    public function param(name:String, defaultValue:Any = null):Any {
        if (queryParams == null) {
            return defaultValue;
        }
        var v = defaultValue;
        if (queryParams.exists(name)) {
            v = queryParams.get(name);
        }
        return v;
    }

    public function paramInt(name:String, defaultValue:Null<Int> = null):Null<Int> {
        if (queryParams == null) {
            return defaultValue;
        }
        var v = defaultValue;
        if (queryParams.exists(name)) {
            v = Std.parseInt(Std.string(queryParams.get(name)));
        }
        return v;
    }

    public function clone():RestRequest {
        var c = new RestRequest();
        c.verb = this.verb;
        c.path = this.path;
        if (this.urlParams != null) {
            c.urlParams = this.urlParams.copy();
        }
        if (this.queryParams != null) {
            c.queryParams = this.queryParams.copy();
        }
        if (this.headers != null) {
            c.headers = this.headers.copy();
        }
        c.body = this.body;
        c.useAlternateConfig = this.useAlternateConfig;

        return c;
    }
}