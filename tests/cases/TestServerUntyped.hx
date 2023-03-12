package cases;

import http.HttpError;
import haxe.io.Bytes;
import rest.RestError;
import http.HttpMethod;
import rest.RestRequest;
import rest.RestClient;
import promises.Promise;
import rest.server.RestServer;
import utest.Assert;
import utest.Async;
import utest.Test;

@:timeout(2000)
class TestServerUntyped extends Test {
    var port:Int = 8876;
    var restServer:RestServer;

    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));

        restServer = new RestServer();
        restServer.start(port);
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    function setup() {
        restServer.clearRoutes();
    }

    function testBasicGet(async:Async) {
        restServer.get("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                restResponse.write("this is the response body");
                resolve(restResponse);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar";
        client.makeRequest(request).then(result -> {
            Assert.equals("this is the response body", result.response.bodyAsString);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
        });
    }

    function testBasicPost(async:Async) {
        restServer.post("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                Assert.equals("this is the request body", restRequest.body);
                restResponse.write("this is the response body");
                resolve(restResponse);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Post;
        request.path = "/foo/bar";
        request.body = "this is the request body";
        client.makeRequest(request).then(result -> {
            Assert.equals("this is the response body", result.response.bodyAsString);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
        });
    }

    function testRouteParams(async:Async) {
        restServer.get("/foo/bar/{userId}", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                Assert.equals(1001, restRequest.paramInt("userId"));
                restResponse.write("this is the response body");
                resolve(restResponse);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar/1001";
        client.makeRequest(request).then(result -> {
            Assert.equals("this is the response body", result.response.bodyAsString);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
        });
    }

    function testRouteParamsAndQueryParams(async:Async) {
        restServer.get("/foo/bar/{userId}", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                Assert.equals(1001, restRequest.paramInt("userId"));
                Assert.equals("value1", restRequest.param("param1"));
                Assert.equals("value2", restRequest.param("param2"));
                restResponse.write("this is the response body");
                resolve(restResponse);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar/1001?param1=value1&param2=value2";
        client.makeRequest(request).then(result -> {
            Assert.equals("this is the response body", result.response.bodyAsString);
            async.done();
        }, (error:RestError) -> {
            Assert.fail();
        });
    }

    function testRouteNotFound(async:Async) {
        restServer.get("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                restResponse.write("this is the response body");
                resolve(restResponse);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar/doesnt_exist";
        client.makeRequest(request).then(result -> {
            Assert.fail();
            return null;
        }, (error:RestError) -> {
            Assert.equals(404, error.httpStatus);
            async.done();
        });
    }

    function testException(async:Async) {
        restServer.get("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                throw "this is an exception";
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar";
        client.makeRequest(request).then(result -> {
            Assert.fail();
            return null;
        }, (error:RestError) -> {
            Assert.equals(500, error.httpStatus);
            Assert.equals("this is an exception", error.bodyAsString);
            async.done();
        });
    }

    function testError(async:Async) {
        restServer.get("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                var restError = new RestError();
                restError.httpStatus = 502;
                restError.body = Bytes.ofString("this is the errror body");
                reject(restError);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar";
        client.makeRequest(request).then(result -> {
            Assert.fail();
            return null;
        }, (error:RestError) -> {
            Assert.equals(502, error.httpStatus);
            Assert.equals("this is the errror body", error.bodyAsString);
            async.done();
        });
    }

    function testHttpError(async:Async) {
        restServer.get("/foo/bar", (restRequest, restResponse) -> {
            return new Promise((resolve, reject) -> {
                var httpError = new HttpError(502);
                httpError.body = Bytes.ofString("this is the errror body");
                reject(httpError);
            });
        });

        var client = new RestClient({
            baseAddress: 'http://localhost:${port}'
        });

        var request = new RestRequest();
        request.verb = HttpMethod.Get;
        request.path = "/foo/bar";
        client.makeRequest(request).then(result -> {
            Assert.fail();
            return null;
        }, (error:RestError) -> {
            Assert.equals(502, error.httpStatus);
            Assert.equals("this is the errror body", error.bodyAsString);
            async.done();
        });
    }
}