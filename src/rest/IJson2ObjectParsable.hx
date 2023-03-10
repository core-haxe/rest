package rest;

@:autoBuild(rest.macros.Json2ObjectParser.build())
interface IJson2ObjectParsable extends IParsable {
    private function toString():String;
}