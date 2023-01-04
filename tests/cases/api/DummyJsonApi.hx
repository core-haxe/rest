package cases.api;

import rest.RestApi;

@:config({
    baseAddress: "https://dummyjson.com/"
})
class DummyJsonApi extends RestApi<DummyError> {
    public var products:DummyProductsApi;   
}
