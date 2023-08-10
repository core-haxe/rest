package rest;

import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Encoding;

class RestResponse {
    public var httpStatus:Int;
    public var headers:Map<String, Any>;

    public var originalRequest:RestRequest;
    private var buffer:BytesBuffer = null;

    public function new() {
    }

    private var _body:Bytes = null;
    public var body(get, set):Bytes;
    private function get_body():Bytes {
        if (_body != null) {
            return _body;
        }
        if (buffer == null) {
            return null;
        }
        _body = buffer.getBytes();
        buffer = null;
        return _body;
    }
    private function set_body(value:Bytes):Bytes {
        buffer = new BytesBuffer();
        buffer.addBytes(value, 0, value.length);
        return value;
    }

    public function write(data:String, encoding:Encoding = null) {
        if (buffer == null) {
            buffer = new BytesBuffer();
        }
        buffer.addString(data, encoding);
    }

    public function writeBytes(data:Bytes) {
        if (buffer == null) {
            buffer = new BytesBuffer();
        }
        buffer.addBytes(data, 0, data.length);
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