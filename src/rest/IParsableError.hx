package rest;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
@:autoBuild(rest.macros.RestErrorBuilder.build())
interface IParsableError {
    public var headers:Map<String, Any>;
    private function parse(error:RestError):Void;
    private function toString():String;
}