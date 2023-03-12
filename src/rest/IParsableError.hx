package rest;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
@:autoBuild(rest.macros.RestErrorBuilder.build())
interface IParsableError {
    private function parse(error:RestError):Void;
}