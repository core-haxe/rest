package rest.server;

import http.HttpError;
import http.HttpRequest;
import http.HttpResponse;
import http.HttpStatus;
import http.server.HttpServer;
import promises.Promise;

using StringTools;

typedef RestFunction = RestRequest->RestResponse->Promise<RestResponse>;

class RestServer {
    private var _httpServer:HttpServer;
    private var _routes:Array<RouteInfo> = [];
    
    public function new() {
        _httpServer = new HttpServer();
        _httpServer.onRequest = onRequest;
    }

    public function start(port:Int) {
        _httpServer.start(port);
    }  

    public function get(path:String, fn:RestFunction) {
        _routes.push({
            method: "get",
            path: path,
            fn: fn
        });
    }

    public function serveFilesFrom(dir:String) {
        _httpServer.serveFilesFrom(dir);
    }

    private function onRequest(httpRequest:HttpRequest, httpResponse:HttpResponse):Promise<HttpResponse> {
        return new Promise((resolve, reject) -> {
            var routeInfo = findRouteInfo(httpRequest.method, httpRequest.url.path);
            if (routeInfo == null) {
                httpResponse.httpStatus = HttpStatus.NotFound;
                resolve(httpResponse);
                return;
            }

            var restRequest = new RestRequest();
            if (restRequest.queryParams == null) {
                restRequest.queryParams = [];
            }
            mergeMap(restRequest.queryParams, routeInfo.varValues);
            var restResponse = new RestResponse();
            restResponse.httpStatus = HttpStatus.Success;
            routeInfo.fn(restRequest, restResponse).then((restResponse) -> {
                httpResponse.httpStatus = restResponse.httpStatus;
                httpResponse.headers = restResponse.headers;
                httpResponse.body = restResponse.body;
                resolve(httpResponse);
            }, error -> {
                if ((error is RestError)) {
                    var restError = cast(error, RestError);
                    var httpError = new HttpError(restError.message, restError.httpStatus);
                    httpError.body = restError.body;
                } else if ((error is HttpError)) {
                    reject(error);
                } else {
                    reject(error);
                }
            });
        });        
    }

    private function findRouteInfo(method:String, path:String):RouteInfo {
        var info = null;
        var pathParts = pathToArray(path);
        var varValues:Map<String, Any> = [];
        for (candidate in _routes) {
            if (candidate.method.toLowerCase() != method.toLowerCase()) {
                continue;
            }

            var candidatePathParts = pathToArray(candidate.path);
            if (pathParts.length != candidatePathParts.length) {
                continue;
            }

            var match = true;
            varValues.clear();
            for (i in 0...candidatePathParts.length) {
                var candidatePathPart = candidatePathParts[i];
                var isVar = (candidatePathPart.startsWith("{") && candidatePathPart.endsWith("}"));
                var pathPart = pathParts[i];
                if (isVar) {
                    varValues.set(candidatePathPart.substring(1, candidatePathPart.length - 1), pathPart);
                } else {
                    if (candidatePathPart != pathPart) {
                        match = false;
                        break;
                    }
                }
            }

            if (match) {
                info = {
                    method: candidate.method,
                    path: candidate.path,
                    fn: candidate.fn,
                    varValues: varValues,
                }
                break;
            }
        }
        return info;
    }

    private static function pathToArray(path:String) {
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        if (path.endsWith("/")) {
            path = path.substring(path.length - 1);
        }
        return path.split("/");
    }

    private static function mergeMap(target:Map<String, Any>, source:Map<String, Any>) {
        for (k in source.keys()) {
            target.set(k, source.get(k));
        }
    }
}

private typedef RouteInfo = {
    var method:String;
    var path:String;
    var fn:RestFunction;
    var ?varValues:Map<String, Any>;
}