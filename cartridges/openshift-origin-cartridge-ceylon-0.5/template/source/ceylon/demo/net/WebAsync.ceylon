import ceylon.net.httpd { HttpResponse, HttpRequest, WebEndpointAsync, WebEndpointConfig, HttpCompletionHandler }

by "Matej Lazar"
shared class WebAsync() extends WebBase() satisfies WebEndpointAsync {
	
	shared actual void init(WebEndpointConfig endpointConfig) {}

	shared actual void service(HttpRequest request, HttpResponse response, HttpCompletionHandler completionHandler) {
		testOperations(request, response);
		completionHandler.handleComplete();
	}
}