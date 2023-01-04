package rest;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
interface IParsable {
    private function parse(response:Any):Void;
}