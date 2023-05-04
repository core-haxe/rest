package rest;

import haxe.Json;
import haxe.io.Bytes;
import http.HttpError;

class RestError {
    public var httpError:HttpError;

    public function new(httpError:HttpError = null, message:String = null) {
        this.httpError = httpError;
        if (message != null) {
            this.message = message;
        }
    }

    private var _httpStatus:Null<Int> = null;
    public var httpStatus(get, set):Null<Int>;
    private function get_httpStatus():Null<Int> {
        if (_httpStatus != null) {
            return _httpStatus;
        }
        if (httpError == null) {
            return null;
        }
        return httpError.httpStatus;
    }
    private function set_httpStatus(value:Null<Int>):Null<Int> {
        _httpStatus = value;
        return value;
    }

    private var _headers:Map<String, Any> = null;
    public var headers(get, set):Map<String, Any>;
    private function get_headers():Map<String, Any> {
        if (_headers != null) {
            return _headers;
        }
        if (httpError == null) {
            return null;
        }
        return httpError.headers;
    }
    private function set_headers(value:Map<String, Any>):Map<String, Any> {
        _headers = value;
        return value;
    }

    private var _message:String;
    public var message(get, set):String;
    private function get_message():String {
        if (_message != null) {
            return _message;
        }
        if (httpError == null) {
            return null;
        }
        return httpError.message;
    }
    private function set_message(value:String):String {
        _message = value;
        return value;
    }

    private var _body:Bytes = null;
    public var body(get, set):Bytes;
    private function get_body():Bytes {
        if (_body != null) {
            return _body;
        }

        if (httpError == null) {
            return null;
        }

        return httpError.body;
    }
    private function set_body(value:Bytes):Bytes {
        _body = value;
        return value;
    }

    public var bodyAsString(get, null):String;
    private function get_bodyAsString():String {
        var body = this.body;
        if (body == null) {
            return null;
        }
        return body.toString();
    }

    public var bodyAsJson(get, null):Dynamic;
    private function get_bodyAsJson():Dynamic {
        var body = this.body;
        if (body == null) {
            return null;
        }
        return Json.parse(body.toString());
    }
}