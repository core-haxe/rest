package rest;

class None implements IMappable implements IParsable  {
    private function toMap():Map<String, Any> {
        return null;
    }

    private function toObject():Dynamic {
        return null;
    }

    private function parse(response:Any) {
    }
}