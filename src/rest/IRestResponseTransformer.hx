package rest;

interface IRestResponseTransformer {
    function process(response:RestResponse):Void;
}