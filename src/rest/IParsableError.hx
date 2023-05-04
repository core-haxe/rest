package rest;

import haxe.io.Bytes;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
@:autoBuild(rest.macros.RestErrorBuilder.build())
interface IParsableError {
    public var httpStatus:Null<Int>;
    public var message:String;
    public var body:Bytes;
    public var headers:Map<String, Any>;
    private function parse(error:RestError):Void;
    private function toString():String;
}