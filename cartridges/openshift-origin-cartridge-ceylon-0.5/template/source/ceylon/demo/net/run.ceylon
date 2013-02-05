import ceylon.net.httpd { Httpd, newHttpdInstance = newInstance, newConfig }

doc "Run the module `ceylon.demo.net`."
by "Matej Lazar"
shared void run() {
	
	print(process.vmVersion);
	
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
	
	httpd.start();
}