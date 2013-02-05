import ceylon.net.httpd { Httpd, newHttpdInstance = newInstance, newConfig }

doc "Run the module `ceylon.demo.net`."
by "Matej Lazar"

String prop_httpd_bind_port = "httpd.bind.port";
String prop_httpd_bind_host = "httpd.bind.host";

shared void run() {
	
	print("Vm version: " + process.vmVersion);
	
	Httpd httpd = newHttpdInstance();
	
	httpd.addWebEndpointConfig(newConfig("/path", "ceylon.demo.net.Web", "ceylon.demo.net:0.5"));
	httpd.addWebEndpointConfig(newConfig("/async", "ceylon.demo.net.WebAsync", "ceylon.demo.net:0.5"));
	
	value filesConfig = newConfig("/file", "ceylon.net.httpd.endpoints.StaticFileEndpoint", "ceylon.net:0.5");	
	//curently supported only external (not in car) file location
	filesConfig.addAttribute("files-dir", "/home/matej/temp/1__ulpload-test/");
	httpd.addWebEndpointConfig(filesConfig);
	
	//TODO load properties from archive
	//httpd.loadWebEndpointConfig(); //defaults to local module
	//httpd.loadWebEndpointConfig("", "/ceylon/demo/net/web.properties"); //alternative file name
	//httpd.loadWebEndpointConfig("module-id"); //
	//httpd.loadWebEndpointConfig("module-id", "web.properties"); //
	
	variable Integer port = 8080;
	if (exists portStr = process.propertyValue(prop_httpd_bind_port)) {
		if (exists p = parseInteger(portStr)) {
			port = p;
		}
	}
	
	variable String host = "127.0.0.1";
	if (exists h = process.propertyValue(prop_httpd_bind_host)) {
		host = h;
	}
	
	httpd.start(port, host);
}