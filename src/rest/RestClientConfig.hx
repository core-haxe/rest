package rest;

import http.IHttpProvider;
import queues.IQueue;
import http.HttpClient.RequestQueueItem;

typedef RestClientConfig =  {
    var baseAddress:String;
    var ?retryCount:Int;
    var ?httpProvider:IHttpProvider;
    var ?requestQueueProvider:Class<IQueue<RequestQueueItem>>;
    var ?requestTransformers:Array<IRestRequestTransformer>;
    var ?responseTransformers:Array<IRestResponseTransformer>;
    var ?defaultRequestHeaders:Map<String, Any>;
}