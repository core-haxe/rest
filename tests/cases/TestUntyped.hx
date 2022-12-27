package cases;

import http.ContentTypes;
import http.StandardHeaders;
import http.HttpMethod;
import utest.Assert;
import rest.RestError;
import rest.RestRequest;
import rest.RestClient;
import utest.Test;
import utest.Async;

@:timeout(2000)
class TestUntyped extends Test {
    private static inline var BASE_URL:String = "https://httpbin.org";

    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    function testUntypedRequest(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/",
            defaultRequestHeaders: [StandardHeaders.ContentType => ContentTypes.ApplicationJson]
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/products";
        client.makeRequest(request).then(result -> {
            var json = result.response.bodyAsJson;
            Assert.equals(100, json.total);
            Assert.equals(0, json.skip);
            Assert.equals(30, json.limit);
            var products:Array<Dynamic> = json.products;
            Assert.equals(30, products.length);
            Assert.equals(1, products[0].id);
            Assert.equals("iPhone 9", products[0].title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }

    function testUntypedRequest_WithUrlParam(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/",
            defaultRequestHeaders: [StandardHeaders.ContentType => ContentTypes.ApplicationJson]
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/products/{id}";
        request.urlParams = ["id" => 6];
        client.makeRequest(request).then(result -> {
            var json = result.response.bodyAsJson;
            Assert.equals(6, json.id);
            Assert.equals("MacBook Pro", json.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }

    function testUntypedRequest_Post(async:Async) {
        var client = new RestClient({
            baseAddress: "https://dummyjson.com/",
            defaultRequestHeaders: [StandardHeaders.ContentType => ContentTypes.ApplicationJson]
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Post;
        request.path = "/products/add";
        request.body = {
            title: "some new title"
        }
        client.makeRequest(request).then(result -> {
            var json = result.response.bodyAsJson;
            Assert.equals(101, json.id);
            Assert.equals("some new title", json.title);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
            async.done();
        });
    }
}