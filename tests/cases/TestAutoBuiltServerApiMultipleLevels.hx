package cases;

import haxe.io.Bytes;
import utest.Assert;
import cases.api.DummyError;
import utest.Async;
import cases.api.SearchProductRequest;
import cases.api.GetProductRequest;
import cases.api.Product;
import cases.api.ProductList;
import promises.Promise;
import cases.api.DummyJsonApi;
import rest.server.RestServerApi;
import utest.Test;

class TestAutoBuiltServerApiMultipleLevels extends Test {
    var port:Int = 9876;
    var testServer:TestDummyServer;

    function setupClass() {
        logging.LogManager.instance.addAdaptor(new logging.adaptors.ConsoleLogAdaptor({
            levels: [logging.LogLevel.Info, logging.LogLevel.Error]
        }));

        testServer = new TestDummyServer();
        testServer.start(port);
    }

    function teardownClass() {
        logging.LogManager.instance.clearAdaptors();
    }

    function setup() {
        //testServer.clearRoutes();
    }

    function testList(async:Async) {
        var api = new DummyJsonApi();
        api.useAlternateConfig = true;
        api.products.list().then(list -> {
            Assert.equals(3, list.total);
            Assert.equals(3, list.products.length);

            Assert.equals(1001, list.products[0].id);
            Assert.equals("Fake product 1001", list.products[0].title);
            
            Assert.equals(2002, list.products[1].id);
            Assert.equals("Fake product 2002", list.products[1].title);
            
            Assert.equals(3003, list.products[2].id);
            Assert.equals("Fake product 3003", list.products[2].title);
            
            async.done();
        }, (error:DummyError) -> {
            Assert.fail();
        });
    }

    function testGet_Exists(async:Async) {
        var api = new DummyJsonApi();
        api.useAlternateConfig = true;
        api.products.get({id: 1001}).then(product -> {
            Assert.equals(1001, product.id);
            Assert.equals("Fake product 1001", product.title);

            async.done();
        }, (error:DummyError) -> {
            Assert.fail();
        });
    }

    function testGet_Exception(async:Async) {
        var api = new DummyJsonApi();
        api.useAlternateConfig = true;
        api.products.get({id: 1111}).then(product -> {
            Assert.fail();
            return null;
        }, (error:DummyError) -> {
            Assert.equals("product 1111 doesnt exist", error.body.toString());
            async.done();
        });
    }

    function testGet_Error(async:Async) {
        var api = new DummyJsonApi();
        api.useAlternateConfig = true;
        api.products.get({id: 1234}).then(product -> {
            Assert.fail();
            return null;
        }, (error:DummyError) -> {
            Assert.equals(404, error.httpStatus);
            Assert.equals("product 1234 doesnt exist", error.body.toString());
            async.done();
        });
    }

    function testSearch(async:Async) {
        var api = new DummyJsonApi();
        api.useAlternateConfig = true;
        api.products.search({query: "products_that_exist"}).then(list -> {
            Assert.equals(2, list.total);
            Assert.equals(2, list.products.length);

            Assert.equals(1001, list.products[0].id);
            Assert.equals("Fake product 1001", list.products[0].title);
            
            Assert.equals(3003, list.products[1].id);
            Assert.equals("Fake product 3003", list.products[1].title);
            
            async.done();
        }, (error:DummyError) -> {
            Assert.fail();
        });
    }
}

@:mapping([
    products => TestDummyServerProducts
])
private class TestDummyServer extends RestServerApi<DummyJsonApi> {
}

private class TestDummyServerProducts {
    public function new() {
    }

    public function list():Promise<ProductList> {
        return new Promise((resolve, reject) -> {
            var list = new ProductList();
            list.total = 3;
            list.products = [];

            var fakeProduct = new Product();
            fakeProduct.id = 1001;
            fakeProduct.title = "Fake product 1001";
            list.products.push(fakeProduct);

            var fakeProduct = new Product();
            fakeProduct.id = 2002;
            fakeProduct.title = "Fake product 2002";
            list.products.push(fakeProduct);

            var fakeProduct = new Product();
            fakeProduct.id = 3003;
            fakeProduct.title = "Fake product 3003";
            list.products.push(fakeProduct);

            resolve(list);
        }); 
    }

    public function get(request:GetProductRequest):Promise<Product> {
        return new Promise((resolve, reject) -> {
            if (request.id == 1001) {
                var fakeProduct = new Product();
                fakeProduct.id = 1001;
                fakeProduct.title = "Fake product 1001";
                resolve(fakeProduct);
            }

            if (request.id == 1111) {
                throw "product 1111 doesnt exist";
            }

            var error = new DummyError();
            error.httpStatus = 404;
            error.body = Bytes.ofString("product " + request.id + " doesnt exist");
            reject(error);
        }); 
    }

    public function search(request:SearchProductRequest):Promise<ProductList> {
        return new Promise((resolve, reject) -> {
            if (request.query == "products_that_exist") {
                var list = new ProductList();
                list.total = 2;
                list.products = [];

                var fakeProduct = new Product();
                fakeProduct.id = 1001;
                fakeProduct.title = "Fake product 1001";
                list.products.push(fakeProduct);

                var fakeProduct = new Product();
                fakeProduct.id = 3003;
                fakeProduct.title = "Fake product 3003";
                list.products.push(fakeProduct);

                resolve(list);
            } else {
                throw "invalid search query";
            }
        }); 
    }
}