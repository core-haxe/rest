package cases.api;

import rest.RestApi;

class DummyProductsApi extends RestApi<DummyError> {
    @:get( "/products",                  ProductList)   public function list();
    @:get( "/products/{id}",             Product)       public function get(request:GetProductRequest);
    @:get( "/products/search?q={query}", ProductList)   public function search(request:SearchProductRequest);
    @:post("/products/add",              Product, Json) public function add(product:Product);
}
