import ceylon.net.http.server.endpoints { serveStaticFile }
import ceylon.net.http.server { Server, createServer, AsynchronousEndpoint, startsWith, Request, Response, Endpoint }

doc "Run the module `ceylon.demo.net`."
by "Matej Lazar"

String prop_httpd_bind_port = "httpd.bind.port";
String prop_httpd_bind_host = "httpd.bind.host";

shared void run() {
    
    print("Vm version: " + process.vmVersion);
    
    Server server = createServer {};
    
    server.addEndpoint(AsynchronousEndpoint {
        service => serveStaticFile("/home/matej/temp/1__ulpload-test/");
        path = startsWith("/file");
    });
    
    server.addEndpoint(Endpoint {
        service => Web().service;
        path = startsWith("/post");
    });
    
    void asyncInvocation(Request request, Response response, Callable<Anything, []> complete) {
        Web().service(request, response);
        complete();
    }
             
    server.addEndpoint(AsynchronousEndpoint {
            path = startsWith("/async");
            service => asyncInvocation;
        }
    );

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
    
    server.start(port, host);
}

