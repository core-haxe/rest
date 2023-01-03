package rest.transformers.request;

typedef AddAuthorizationHeaderConfig = {
    var value:String;
    @:optional var headerName:String;
}

class AddAuthorizationHeader implements IRestRequestTransformer {
    public var config:AddAuthorizationHeaderConfig;

    public function new(config:AddAuthorizationHeaderConfig) {
        this.config = config;
    }

    public function process(request:RestRequest) {
        var headerName = config.headerName;
        if (headerName == null || headerName == "") {
            headerName = "Authorization";
        }

        if (headerName == null) {
            throw "no header name specified";
        }
        if (config.value == null || config.value == "") {
            throw "no header value specified";
        }

        request.addHeader(headerName, config.value);
    }
}