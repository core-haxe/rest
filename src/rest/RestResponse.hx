package rest;

import haxe.io.Bytes;
import haxe.Json;

class RestResponse {
    public var httpStatus:Int;
    public var headers:Map<String, Any>;
    public var body:Bytes;

    public var originalRequest:RestRequest;

    public function new() {
    }

    public var bodyAsString(get, null):String;
    private function get_bodyAsString():String {
        if (body == null) {
            return null;
        }

        return body.toString();
    }

    public var bodyAsJson(get, null):Dynamic;
    private function get_bodyAsJson():Dynamic {
        if (body == null) {
            return null;
        }

        return Json.parse(body.toString());
    }

    public var contentType(get, null):String;
    private function get_contentType():String {
        if (headers == null) {
            return null;
        }
        var header = headers.get("content-type");
        if (header == null) {
            header = headers.get("Content-Type");
        }

        return header;
    }
}