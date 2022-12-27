package cases;

import rest.BodyType;
import rest.None;
import rest.RestOperation;
import http.HttpMethod;
import utest.Assert;
import rest.RestError;
import rest.RestClient;
import utest.Test;
import utest.Async;
import cases.api.Product;
import cases.api.ProductList;
import cases.api.DummyError;
import cases.api.GetProductRequest;

@:timeout(2000)
class TestAutoMappingParsing extends Test {
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

        var operation = new RestOperation<None, ProductList, DummyError>();
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

        var operation = new RestOperation<GetProductRequest, Product, DummyError>();
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

        var operation = new RestOperation<Product, Product, DummyError>();
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
