package rest;

interface IMappable {
    private function toMap():Map<String, Any>;
    private function toObject():Dynamic;
}