package rest;

import haxe.Constraints.Constructible;

@:autoBuild(rest.macros.RestApiBuilder.build())
class RestApi<TError:Constructible<Void->Void> & IParsableError> {
    private var client:RestClient;
    private var parentApi:RestApi<TError> = null;

    public function new(client:RestClient = null, parentApi:RestApi<TError> = null) {
        this.client = client;
        this.parentApi = parentApi;
        if (this.client == null) {
            this.client = new RestClient();
        }
    }

    private var _useAlternateConfig:Bool = false;
    private var useAlternateConfig(get, set):Bool;
    private function get_useAlternateConfig():Bool {
        if (parentApi == null) {
            return _useAlternateConfig;
        }
        return parentApi.useAlternateConfig;
    }
    private function set_useAlternateConfig(value:Bool) {
        if (parentApi == null) {
            _useAlternateConfig = value;
            return value;
        }

        parentApi.useAlternateConfig = value;
        return value;
    }

}