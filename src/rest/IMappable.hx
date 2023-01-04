package rest;

@:autoBuild(rest.macros.AddDefaultConstructor.build())
interface IMappable {
    private function toMap():Map<String, Any>;
    private function toObject():Dynamic;
}