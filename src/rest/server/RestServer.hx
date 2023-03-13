package rest.server;

import http.HttpError;
import http.HttpRequest;
import http.HttpResponse;
import http.HttpStatus;
import http.Url;
import http.server.HttpServer;
import logging.Logger;
import promises.Promise;

using StringTools;

typedef RestFunction = RestRequest->RestResponse->Promise<RestResponse>;

class RestServer {
    private var log:Logger = new Logger(RestServer);

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
        var url = Url.fromString(path);
        log.info('registering "get" route "${url.path}"');
        _routes.push({
            method: "get",
            path: url.path,
            fn: fn,
            paramMapping: mapParams(url.queryParams)
        });
        sortRoutes();
    }

    public function post(path:String, fn:RestFunction) {
        var url = Url.fromString(path);
        log.info('registering "post" route "${url.path}"');
        _routes.push({
            method: "post",
            path: url.path,
            fn: fn,
            paramMapping: mapParams(url.queryParams)
        });
        sortRoutes();
    }

    private function mapParams(queryParams:Map<String, Any>) { 
        var paramMapping:Map<String, String> = null;
        if (queryParams != null) {
            for (k in queryParams.keys()) {
                if (paramMapping == null) {
                    paramMapping = [];
                }
                var v = Std.string(queryParams.get(k));
                if (v.startsWith("{") && v.endsWith("}")) {
                    paramMapping.set(k, v.substring(1, v.length - 1));
                }
            }
        }

        return paramMapping;
    }

    private function sortRoutes() {
        _routes.sort((route1, route2) -> {
            var route1Vars = (route1.path.indexOf("{") != -1 && route1.path.indexOf("}") != -1);
            var route2Vars = (route2.path.indexOf("{") != -1 && route2.path.indexOf("}") != -1);
            if (route1Vars && !route2Vars) {
                return 1;
            } else if (!route1Vars && route2Vars) {
                return -1;
            }
            return 0;
        });
    }

    public function clearRoutes() {
        _routes = [];
    }

    public function serveFilesFrom(dir:String) {
        _httpServer.serveFilesFrom(dir);
    }

    private function onRequest(httpRequest:HttpRequest, httpResponse:HttpResponse):Promise<HttpResponse> {
        return new Promise((resolve, reject) -> {
            var routeInfo = findRouteInfo(httpRequest.method, httpRequest.url.path);
            if (routeInfo == null) {
                log.error('could not find route for "${httpRequest.url.path}"');
                httpResponse.httpStatus = HttpStatus.NotFound;
                resolve(httpResponse);
                return;
            }

            var restRequest = new RestRequest();
            if (restRequest.queryParams == null) {
                restRequest.queryParams = [];
            }
            restRequest.body = httpRequest.body;
            mergeMap(restRequest.queryParams, httpRequest.queryParams);
            mergeMap(restRequest.queryParams, routeInfo.varValues);
            if (routeInfo.paramMapping != null) {
                for (k in routeInfo.paramMapping.keys()) {
                    var v = routeInfo.paramMapping.get(k);
                    if (restRequest.queryParams.exists(k)) {
                        restRequest.queryParams.set(v, restRequest.queryParams.get(k));
                        restRequest.queryParams.remove(k);
                    }
                }
            }

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
                    reject(httpError);
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
            varValues.clear();
            var match = isRouteMatch(candidate, method, pathParts, varValues);
            if (match) {
                info = {
                    method: candidate.method,
                    path: candidate.path,
                    fn: candidate.fn,
                    varValues: varValues,
                    paramMapping: candidate.paramMapping
                }
                break;
            }
        }
        return info;
    }

    private function isRouteMatch(candidate:RouteInfo, method:String, pathParts:Array<String>, varValues:Map<String, Any>) {
        if (candidate.method.toLowerCase() != method.toLowerCase()) {
            return false;
        }

        var candidatePathParts = pathToArray(candidate.path);
        if (pathParts.length != candidatePathParts.length) {
            return false;
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

        return match;
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
    var ?paramMapping:Map<String, Any>;
}