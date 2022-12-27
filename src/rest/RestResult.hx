package rest;

class RestResult {
    public var client:RestClient;
    public var response:RestResponse;

    public function new(client:RestClient, response:RestResponse = null) {
        this.client = client;
        this.response = response;
    }
}