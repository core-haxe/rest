package rest;

interface IRestRequestTransformer {
    function process(request:RestRequest, transformationParams:Map<String, Any> = null):Void;
}