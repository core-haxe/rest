package cases;

import utest.Async;
import utest.Assert;
import promises.Promise;
import rest.server.RestServerApi;
import rest.IJson2ObjectParsable;
import rest.IMappableAuto;
import rest.IParsableError;
import rest.RestApi;
import utest.Test;

class TestFibonacci extends Test {
    var port:Int = 6345;
    var testServer:FibonacciServer;
    
    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));

        testServer = new FibonacciServer();
        testServer.start(port);
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    public function testBasic(async:Async) {
        var api = new FibonacciApi();
        api.generate({count: 10}).then(response -> {
            Assert.equals(10, response.numbers.length);
            Assert.same([0, 1, 1, 2, 3, 5, 8, 13, 21, 34], response.numbers);
            async.done();
        }, (error:FibonacciError) -> {
            Assert.fail();
        });
    }
}

class FibonacciError implements IParsableError {
}

@:config({
    baseAddress: "http://localhost:6345/"
})
class FibonacciApi extends RestApi<FibonacciError> {
    @:get("/generate/{count}", GenerateResponse)   public function generate(request:GenerateRequest);
}

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

@:structInit
class GenerateRequest implements IMappableAuto {
    public var count:Int;
}

class GenerateResponse implements IJson2ObjectParsable {
    public var numbers:Array<Int>;
}
