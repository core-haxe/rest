package cases;

import utest.Async;
import utest.Assert;
import cases.api.SearchProductRequest;
import cases.api.GetProductRequest;
import haxe.io.Bytes;
import cases.api.DummyError;
import cases.api.Product;
import cases.api.ProductList;
import promises.Promise;
import cases.api2.DummyProductsApi;
import rest.server.RestServerApi;
import utest.Test;

class TestAutoBuiltServerApiSingleLevel extends Test {
    var port:Int = 7876;
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
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        api.list().then(list -> {
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
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        api.get({id: 1001}).then(product -> {
            Assert.equals(1001, product.id);
            Assert.equals("Fake product 1001", product.title);

            async.done();
        }, (error:DummyError) -> {
            Assert.fail();
        });
    }

    function testGet_Exception(async:Async) {
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        api.get({id: 1111}).then(product -> {
            Assert.fail();
            return null;
        }, (error:DummyError) -> {
            Assert.equals("product 1111 doesnt exist", error.body.toString());
            async.done();
        });
    }

    function testGet_Error(async:Async) {
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        api.get({id: 1234}).then(product -> {
            Assert.fail();
            return null;
        }, (error:DummyError) -> {
            Assert.equals(404, error.httpStatus);
            Assert.equals("product 1234 doesnt exist", error.body.toString());
            async.done();
        });
    }

    function testSearch(async:Async) {
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        api.search({query: "products_that_exist"}).then(list -> {
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

    function testPost(async:Async) {
        var api = new DummyProductsApi();
        api.useAlternateConfig = true;
        var newProduct = new Product();
        newProduct.id = 6666;
        newProduct.title = "This is product 6666";
        api.add(newProduct).then(product -> {
            Assert.notNull(product);
            Assert.equals(6666, product.id);
            Assert.equals("This is product 6666", product.title);
            async.done();
        }, (error:DummyError) -> {
            Assert.fail();
        });
    }
}

private class TestDummyServer extends RestServerApi<DummyProductsApi> {
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

    public function add(product:Product):Promise<Product> {
        return new Promise((resolve, reject) -> {
            var fakeProduct = new Product();
            fakeProduct.id = product.id;
            fakeProduct.title = product.title;
            resolve(fakeProduct);
        });
    }
}
