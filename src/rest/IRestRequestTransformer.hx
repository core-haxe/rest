package rest;

interface IRestRequestTransformer {
    function process(request:RestRequest):Void;
}