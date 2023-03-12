package rest;

import http.HttpClient;
import http.HttpError;
import http.HttpRequest;
import http.Url;
import logging.Logger;
import promises.Promise;

using StringTools;

class RestClient {
    private var log:Logger = new Logger(RestClient);

    public var config:RestClientConfig = null;
    public var alternativeConfig:RestClientConfig = null;

    public function new(config:RestClientConfig = null, alternativeConfig:RestClientConfig = null) {
        this.config = config;
        if (this.config == null) {
            this.config = {
                baseAddress: null
            };
        }
        this.alternativeConfig = alternativeConfig;
    }

    public function makeRequest(request:RestRequest, tranformationParams:Map<String, Any> = null):Promise<RestResult> {
        var request = request.clone();

        var baseAddress = config.baseAddress;
        if (request.useAlternateConfig && alternativeConfig != null) {
            baseAddress = alternativeConfig.baseAddress;
        }
        var url = new Url(baseAddress);

        if (request.path != null) {
            url.path += request.path;
        }
        if (request.urlParams != null) {
            for (key in request.urlParams.keys()) {
                url.path = url.path.replace('{${key}}', Std.string(request.urlParams.get(key)));
            }
        }

        // we want to do the replacement of query params here (eg: ?foo={bar}&constant=somevalue)
        // however, critically, if a param value is supposed be replaced (eg: {bar}) but doesnt
        // exist as a param passed in, we want to actually remove it from the query params
        // since sending null / blank values, can lead to bad results, eg:
        //     ?foo={bar}&constant=somevalue
        // should be
        //     ?constant=somevalue
        // if "bar" isnt supplied
        if (request.queryParams != null) {
            for (queryParamKey in request.queryParams.keys()) {
                var queryParamValue = request.queryParams.get(queryParamKey);
                var stringValue = Std.string(queryParamValue);
                if (stringValue.startsWith("{") && stringValue.endsWith("}")) {
                    var actualParamKey = stringValue.substring(1, stringValue.length - 1);
                    var actualParamValue = null;
                    if (request.urlParams != null) {
                        actualParamValue = request.urlParams.get(actualParamKey);
                    }
                    if (actualParamValue == null) {
                        request.queryParams.remove(queryParamKey);
                    } else {
                        stringValue = stringValue.replace('{${actualParamKey}}', request.urlParams.get(actualParamKey));
                        request.queryParams.set(queryParamKey, stringValue);
                    }
                }
            }
        }

        var requestTransformers = config.requestTransformers;
        if (request.useAlternateConfig && alternativeConfig != null) {
            requestTransformers = alternativeConfig.requestTransformers;
        }
        if (requestTransformers != null && requestTransformers.length > 0) {
            for (requestTransformer in requestTransformers) {
                requestTransformer.process(request, tranformationParams);
            }
        }

        var httpRequest = new HttpRequest();
        httpRequest.url = url;
        httpRequest.method = request.verb;
        httpRequest.headers = request.headers;
        httpRequest.queryParams = request.queryParams;
        httpRequest.body = request.body;

        return new Promise((resolve, reject) -> {
            httpClient.makeRequest(httpRequest).then(httpResult -> {
                var restResponse = new RestResponse();
                restResponse.httpStatus = httpResult.response.httpStatus;
                restResponse.headers = httpResult.response.headers;
                restResponse.body = httpResult.response.body;
                resolve(new RestResult(this, restResponse));
            }, (httpError:HttpError) -> {
                var restError = new RestError(httpError);
                reject(restError);
            });
        });
    }

    private var _httpClient:HttpClient = null;
    private var httpClient(get, null):HttpClient;
    private function get_httpClient():HttpClient {
        if (_httpClient != null) {
            return _httpClient;
        }
        _httpClient = new HttpClient();
        if (config.httpProvider != null) {
            _httpClient.provider = config.httpProvider;
        }
        if (config.requestQueue != null) {
            _httpClient.requestQueue = config.requestQueue;
        }
        if (config.defaultRequestHeaders != null) {
            _httpClient.defaultRequestHeaders = config.defaultRequestHeaders;
        }
        if (config.retryCount != null) {
            _httpClient.retryCount = config.retryCount;
        }
        return _httpClient;
    }
}