package cases.api2;

import rest.RestApi;
import cases.api.DummyError;
import cases.api.ProductList;
import cases.api.Product;
import cases.api.GetProductRequest;
import cases.api.SearchProductRequest;

/*
this is the same api, but this version doesnt have nested apis ie:
not "new Api().subApi.operation", but just "new Api().operation" 
this is mainly to make sure the generation macros are behaving
*/
@:config({
    baseAddress: "https://dummyjson.com/"
})
class DummyProductsApi extends RestApi<DummyError> {
    @:get( "/products",                  ProductList)   public function list();
    @:get( "/products/{id}",             Product)       public function get(request:GetProductRequest);
    @:get( "/products/search?q={query}", ProductList)   public function search(request:SearchProductRequest);
    @:post("/products/add",              Product, Json) public function add(product:Product);
}
