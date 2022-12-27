package rest;

import haxe.Constraints.Constructible;

@:autoBuild(rest.macros.RestApiBuilder.build())
class RestApi<TError:Constructible<Void->Void> & IParsableError> {
    private var client:RestClient;

    public function new(client:RestClient = null) {
        this.client = client;
        if (this.client == null) {
            this.client = new RestClient();
        }
    }
}