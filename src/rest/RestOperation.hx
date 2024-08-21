package rest;

import haxe.Constraints.Constructible;
import haxe.Json;
import haxe.http.HttpMethod;
import haxe.io.Bytes;
import http.ContentTypes;
import http.HttpMethod;
import http.StandardHeaders;
import promises.Promise;

using StringTools;

@:generic
@:access(rest.IMappable)
@:access(rest.IParsable)
@:access(rest.IParsableError)
class RestOperation<TRequest:IMappable,
                    TResponse:Constructible<Void->Void> & IParsable,
                    TError:Constructible<Void->Void> & IParsableError> {
    public var verb:HttpMethod = HttpMethod.Get;
    public var path:String;
    public var queryParams:Map<String, Any>;
    public var bodyType:BodyType = BodyType.None;
    public var client:RestClient;
    public var useAlternateConfig:Bool = false;
    public var transformationParams:Map<String, Any>;

    public function new() {
    }

    public function call(request:TRequest = null):Promise<TResponse> {
        return new Promise((resolve, reject) -> {
            var restRequest = new RestRequest();
            var requestParamMap = null;
            if (request != null) {
                requestParamMap = request.toMap();
            }
            restRequest.urlParams = requestParamMap;
            restRequest.queryParams = queryParams;
            restRequest.verb = verb;
            restRequest.path = path;
            restRequest.useAlternateConfig = this.useAlternateConfig;

            if (restRequest.verb != "get" && bodyType != BodyType.None) {
                switch (bodyType) {
                    case BodyType.Json:
                        if (request != null) restRequest.body = request.toObject();
                        if (restRequest.headers == null) {
                            restRequest.headers = [StandardHeaders.ContentType => ContentTypes.ApplicationJson];
                        } else if (!restRequest.headers.exists(StandardHeaders.ContentType)) {
                            restRequest.headers.set(StandardHeaders.ContentType, ContentTypes.ApplicationJson);
                        }
                    case BodyType.FormData: 
                        #if (!nodejs) 

                        var formFields = request.toMap();
                        if (restRequest.queryParams == null) {
                            restRequest.queryParams = [];
                        }
                        for (k in formFields.keys()) {
                            var v = formFields.get(k);
                            restRequest.queryParams.set(k, v);
                        }

                        #else

                        var formData = new http.FormData();
                        var formFields = request.toMap();
                        for (k in formFields.keys()) {
                            var v = formFields.get(k);
                            formData.append(k, v);
                        }
                        var body = formData.build();
                        if (restRequest.headers == null) {
                            restRequest.headers = [];
                        }
                        var formDataHeaders = formData.buildHeaders();
                        for (k in formDataHeaders.keys()) {
                            var v = formDataHeaders.get(k);
                            if (k == "content-type") {
                                restRequest.addHeader(StandardHeaders.ContentType, v);
                            }
                        }

                        restRequest.body = body;

                        #end
                    case _:    
                }
            }

            client.makeRequest(restRequest, transformationParams).then(restResult -> {
                var response = new TResponse();
                var contentType = restResult.response.contentType;
                var responseBody:Any = restResult.response.bodyAsString;
                /* dont think we want to auto parse response bodies, this is what the response parsers are for
                if (contentType != null) {
                    if (contentType.startsWith(ContentTypes.ApplicationJson)) {
                        //responseBody = Json.parse(restResult.response.bodyAsString);
                    }
                }
                */

                try {
                    response.parse(responseBody);
                } catch (e:Dynamic) {
                    var restError = new RestError();
                    restError.body = Bytes.ofString(Std.string(e));
                    var error = new TError();
                    error.parse(restError);
                    reject(error);
                }
                resolve(response);
            }, error -> {
                if ((error is RestError)) {
                    var restError = cast(error, RestError);
                    var error = new TError();
                    error.parse(restError);
                    reject(error);
                } else {
                    reject(error);
                }
            });
        });
    }
}