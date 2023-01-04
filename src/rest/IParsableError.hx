package rest;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
interface IParsableError {
    private function parse(error:RestError):Void;
}