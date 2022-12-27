package cases;

import cases.api.DummyJsonApi;
import cases.api.Product;
import utest.Assert;
import rest.RestClient;
import utest.Async;
import rest.RestError;
import utest.Test;

@:timeout(2000)
class TestAutoBuiltApi extends Test {
    private static inline var BASE_URL:String = "https://httpbin.org";

    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    function testList(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var api = new DummyJsonApi(client);
        api.products.list().then(result -> {
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

    function testGet(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var api = new DummyJsonApi(client);
        api.products.get({id: 6}).then(result -> {
            Assert.equals(6, result.id);
            Assert.equals("MacBook Pro", result.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }
    
    function testSearch(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var api = new DummyJsonApi(client);
        api.products.search({query: "Laptop"}).then(result -> {
            Assert.equals(3, result.total);
            Assert.equals(0, result.skip);
            Assert.equals(3, result.limit);
            Assert.equals(3, result.products.length);
            Assert.equals(7, result.products[0].id);
            Assert.equals("Samsung Galaxy Book", result.products[0].title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }

    function testAdd(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/"
        });

        var api = new DummyJsonApi(client);
        var product = new Product();
        product.title = "some new title";
        api.products.add(product).then(result -> {
            Assert.equals(101, result.id);
            Assert.equals("some new title", result.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }
}





