<a href="https://github.com/core-haxe/rest/actions/workflows/nodejs.yaml"><img src="https://github.com/core-haxe/rest/actions/workflows/nodejs.yaml/badge.svg">
<a href="https://github.com/core-haxe/rest/actions/workflows/hl.yaml"><img src="https://github.com/core-haxe/rest/actions/workflows/hl.yaml/badge.svg">
<a href="https://github.com/core-haxe/rest/actions/workflows/hxcpp.yaml"><img src="https://github.com/core-haxe/rest/actions/workflows/hxcpp.yaml/badge.svg">
<a href="https://github.com/core-haxe/rest/actions/workflows/neko.yaml"><img src="https://github.com/core-haxe/rest/actions/workflows/neko.yaml/badge.svg">

# rest

rest client and server supporting fully typed rest operations

# features

- Promise based
- Ability to create fully typed rest operations (optional)
- Ability to auto parse responses (via things like Json2Object)
- Ability to craft full rest api definitions with little effort

# basic usage (typed)

```haxe
class ProductList implements IJson2ObjectParsable {
    public var total:Int;
    public var skip:Int;
    public var limit:Int;
    public var products:Array<Product>;
}

class Product implements IMappableAuto implements IJson2ObjectParsable {
    public var id:Int;
    public var title:String;
}

@:structInit
class GetProductRequest implements IMappableAuto {
    public var id:Int;
}

class DummyError implements IParsableError {
    public function new() {
    }

    private function parse(error:RestError) {
    }
}

var client = new RestClient({
    baseAddress: "https://dummyjson.com/"
});

// simple operation
var operation = new RestOperation<None, ProductList, DummyError>();
operation.path = "/products";
operation.verb = HttpMethod.Get;
operation.client = client;
operation.call().then(result -> { // "result" is of type "ProductList"
    trace(result.products[0].id);
}, (error:DummyError) -> {
    // error
});

// operation with path parameters
var operation = new RestOperation<GetProductRequest, Product, DummyError>();
operation.path = "/products/{id}";
operation.verb = HttpMethod.Get;
operation.client = client;
operation.call({id: 6}).then(result -> { // "result" is of type "Product"
    trace(result.id);
}, (error:DummyError) -> {
    // error
});

// post operation with body
var operation = new RestOperation<Product, Product, DummyError>();
operation.path = "/products/add";
operation.verb = HttpMethod.Post;
operation.bodyType = BodyType.Json;
operation.client = client;
var product = new Product();
product.title = "some new title";
operation.call(product).then(result -> { // "result" is of type "Product"
    trace(result.id);
}, (error:DummyError) -> {
    // error
});

```

# auto built client api (typed)

```haxe
@:structInit
class SearchProductRequest implements IMappableAuto {
    public var query:String;
}

class DummyProductsApi extends RestApi<DummyError> {
    @:get( "/products",                  ProductList)   public function list();
    @:get( "/products/{id}",             Product)       public function get(request:GetProductRequest);
    @:get( "/products/search?q={query}", ProductList)   public function search(request:SearchProductRequest);
    @:post("/products/add",              Product, Json) public function add(product:Product);
}

class DummyJsonApi extends RestApi<DummyError> {
    public var products:DummyProductsApi;   
}

var client = new RestClient({
    baseAddress: "https://dummyjson.com/"
});
var api = new DummyJsonApi(client);

// simple api call
api.products.list().then(result -> { // "result" is of type "ProductList"
    trace(result.products[0].id);
}, (error:DummyError) -> {
    // error
});

// api call with path parameter
api.products.get({id: 6}).then(result -> { // "result" is of type "Product"
    trace(result.id);
}, (error:DummyError) -> {
    // error
});

// api call with query parameter
api.products.search({query: "Laptop"}).then(result -> { // "result" is of type "ProductList"
    trace(result.products[0].id);
}, (error:DummyError) -> {
    // error
});

// put api call with body
var product = new Product();
product.title = "some new title";
api.products.add(product).then(result -> { // "result" is of type "Product"
    trace(result.id);
}, (error:DummyError) -> {
    // error
});

```

# auto built server api (typed)
using the api we defined previously, it is now possible to use that api definition to build a fully typed rest server where all these is needed is building the functions that perform the server business logic, eg:

```haxe
@:mapping([
    products => TestDummyServerProducts // this tells the system to use functions on this class when a sub api is used
])
private class TestDummyServer extends RestServerApi<DummyJsonApi> {
}

private class TestDummyServerProducts {
    public function new() {
    }
    
    public function list():Promise<ProductList> {
        return new Promise((resolve, reject) -> {
            var list = new ProductList();
            ...
            resolve(list);
        }
    }
    
    public function get(request:GetProductRequest):Promise<Product> {
        return new Promise((resolve, reject) -> {
            var product = new Product();
            ...
            resolve(product);
        }
    }
    
    public function search(request:SearchProductRequest):Promise<ProductList> {
        return new Promise((resolve, reject) -> {
            var list = new ProductList();
            ...
            resolve(list);
        }
    }
}
```

# basic usage (untyped)

```haxe
var client = new RestClient({
    baseAddress: "https://dummyjson.com/",
    defaultRequestHeaders: [StandardHeaders.ContentType => ContentTypes.ApplicationJson]
});

// simple request
var request = new RestRequest();
request.verb = HttpMethod.Get;
request.path = "/products";
client.makeRequest(request).then(result -> {
    trace(result.response.bodyAsJson.products[0].id);
}, (error:RestError) -> {
    // error
});

// request with path parameters
var request = new RestRequest();
request.verb = HttpMethod.Get;
request.path = "/products/{id}";
request.urlParams = ["id" => 6];
client.makeRequest(request).then(result -> {
    trace(result.response.bodyAsJson.id);
}, (error:RestError) -> {
    // error
});

// post request with a body
var request = new RestRequest();
request.verb = HttpMethod.Post;
request.path = "/products/add";
request.body = {
    title: "some new title"
}
client.makeRequest(request).then(result -> {
    trace(result.response.bodyAsJson.id);
}, (error:RestError) -> {
    // error
});

```

# putting it all together (fibonacci client / server api)
```haxe
// basic api parts
class FibonacciError implements IParsableError {
}

@:structInit
class GenerateRequest implements IMappableAuto {
    public var count:Int;
}

class GenerateResponse implements IJson2ObjectParsable {
    public var numbers:Array<Int>;
}

class FibonacciApi extends RestApi<FibonacciError> {
    @:get("/generate/{count}", GenerateResponse)   public function generate(request:GenerateRequest);
}

// server creation / impl
class FibonacciServer extends RestServerApi<FibonacciApi> {
    public function generate(request:GenerateRequest):Promise<GenerateResponse> {
        return new Promise((resolve, reject) -> {
            var response = new GenerateResponse();
            response.numbers = [];
            var n1 = 0, n2 = 1, nextTerm;
            for (_ in 0...request.count) {
                response.numbers.push(n1);
                nextTerm = n1 + n2;
                n1 = n2;
                n2 = nextTerm;
            }
            resolve(response);
        });
    }
}

...

testServer = new FibonacciServer();
testServer.start(1234);

...

// client usage
var client = new RestClient({
    baseAddress: "http://localhost:1234/"
});
var api = new FibonacciApi(client);
api.generate({count: 10}).then(response -> {
    // response.numbers = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
}, (error:FibonacciError) -> {
});
```
