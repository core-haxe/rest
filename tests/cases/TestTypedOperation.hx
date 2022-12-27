package cases;

import rest.BodyType;
import rest.IMappable;
import rest.None;
import rest.IParsable;
import rest.IParsableError;
import rest.RestOperation;
import http.HttpMethod;
import utest.Assert;
import rest.RestError;
import rest.RestClient;
import utest.Test;
import utest.Async;

@:timeout(2000)
class TestTypedOperation extends Test {
    private static inline var BASE_URL:String = "https://httpbin.org";

    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    function testTypedOperation(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var operation = new RestOperation<None, ProductList, ProductError>();
        operation.path = "/products";
        operation.verb = HttpMethod.Get;
        operation.client = client;
        operation.call().then(result -> {
            Assert.equals(100, result.total);
            Assert.equals(0, result.skip);
            Assert.equals(30, result.limit);
            Assert.equals(30, result.products.length);
            Assert.equals(1, result.products[0].id);
            Assert.equals("iPhone 9", result.products[0].title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }

    function testTypedOperation_WithUrlParams(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var operation = new RestOperation<GetProductRequest, Product, ProductError>();
        operation.path = "/products/{id}";
        operation.verb = HttpMethod.Get;
        operation.client = client;
        operation.call({id: 6}).then(result -> {
            Assert.equals(6, result.id);
            Assert.equals("MacBook Pro", result.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }

    function testTypedOperation_Post(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var operation = new RestOperation<Product, Product, ProductError>();
        operation.path = "/products/add";
        operation.verb = HttpMethod.Post;
        operation.bodyType = BodyType.Json;
        operation.client = client;

        var product = new Product();
        product.title = "some new title";
        operation.call(product).then(result -> {
            Assert.equals(101, result.id);
            Assert.equals("some new title", result.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }
}

private class ProductList implements IParsable {
    public var total:Int;
    public var skip:Int;
    public var limit:Int;
    public var products:Array<Product>;

    public function new() {
    }

    private function parse(response:Any) {
        var json = haxe.Json.parse(response);
        this.total = json.total;
        this.skip = json.skip;
        this.limit = json.limit;
        products = [];
        var productsJson:Array<Dynamic> = json.products;
        for (productJson in productsJson) {
            var product = new Product();
            product.id = productJson.id;
            product.title = productJson.title;
            products.push(product);
        }
    }
}

private class Product implements IMappable implements IParsable {
    public var id:Int;
    public var title:String;

    public function new() {
    }

    private function toMap():Map<String, Any> {
        return ["id" => id, "title" => title];
    }

    private function toObject():Dynamic {
        return {
            id: id,
            title: title
        };
    }

    private function parse(response:Any) {
        var json = haxe.Json.parse(response);
        this.id = json.id;
        this.title = json.title;
    }
}

@:structInit
private class GetProductRequest implements IMappable {
    public var id:Int;

    private function toMap():Map<String, Any> {
        return ["id" => id];
    }

    private function toObject():Dynamic {
        return {
            id: id
        };
    }
}

private class ProductError implements IParsableError {
    public function new() {
    }

    private function parse(error:RestError) {

    }
}

