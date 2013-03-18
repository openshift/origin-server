import ceylon.net.http.server.endpoints { serveStaticFile }
import ceylon.net.http.server { Server, createServer, AsynchronousEndpoint, startsWith, Request, Response, Endpoint }

doc "Run the module `ceylon.demo.net`."
by "Matej Lazar"

String prop_server_bind_port = "server.bind.port";
String prop_server_bind_host = "server.bind.host";
String prop_server_files_lcation = "server.files.location";

shared void run() {
    
    print("Vm version: " + process.vmVersion);
    
    Server server = createServer {};
    
    if (exists files = process.propertyValue(prop_server_files_lcation)) {
        server.addEndpoint(AsynchronousEndpoint {
            service => serveStaticFile(files);
            path = startsWith("/file");
        });
    }
    
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
    if (exists portStr = process.propertyValue(prop_server_bind_port)) {
        if (exists p = parseInteger(portStr)) {
            port = p;
        }
    }

    variable String host = "127.0.0.1";
    if (exists h = process.propertyValue(prop_server_bind_host)) {
        host = h;
    }
    
    server.start(port, host);
}

