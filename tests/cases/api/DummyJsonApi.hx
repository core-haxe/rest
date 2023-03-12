package cases.api;

import rest.RestApi;

@:config({
    baseAddress: "https://dummyjson.com/"
})
@:alternateConfig({
    baseAddress: "http://localhost:9876/"
})
class DummyJsonApi extends RestApi<DummyError> {
    public var products:DummyProductsApi;   
}
