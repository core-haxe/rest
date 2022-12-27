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

    public function new() {
    }
}