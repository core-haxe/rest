package rest;

import http.HttpError;
import http.Url;
import http.HttpRequest;
import promises.Promise;
import http.HttpClient;
import logging.Logger;

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

    public function makeRequest(request:RestRequest):Promise<RestResult> {
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

                if (request.queryParams != null) {
                    for (queryParamKey in request.queryParams.keys()) {
                        var queryParamValue = request.queryParams.get(queryParamKey);
                        var stringValue = Std.string(queryParamValue);
                        if (stringValue.indexOf("{") != -1 && stringValue.indexOf("}") != -1) {
                            stringValue = stringValue.replace('{${key}}', request.urlParams.get(key));
                            request.queryParams.set(queryParamKey, stringValue);
                        }
                    }
                }
            }
        }

        var requestTransformers = config.requestTransformers;
        if (request.useAlternateConfig && alternativeConfig != null) {
            requestTransformers = alternativeConfig.requestTransformers;
        }
        if (requestTransformers != null && requestTransformers.length > 0) {
            var copy = request.clone();
            for (requestTransformer in requestTransformers) {
                requestTransformer.process(copy);
            }
            request = copy;
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
        if (config.requestQueueProvider != null) {
            _httpClient.requestQueueProvider = config.requestQueueProvider;
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