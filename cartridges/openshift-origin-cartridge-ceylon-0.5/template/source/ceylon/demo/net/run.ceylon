import ceylon.net.http.server.endpoints { serveStaticFile }
import ceylon.net.http.server { Server, createServer, AsynchronousEndpoint, startsWith, Endpoint, isRoot}
import ceylon.demo.net.todo { demo }

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
            path = startsWith("/css") or startsWith("/img") or startsWith("/js");
            service => serveStaticFile(files);
        });
        
        server.addEndpoint(Endpoint {
            path = isRoot();
            service => welcomePage("``files``/index.html");
        });
        print("Serving static files from ``files``.");
    } else {
        print("To serve static files define VM argument server.files.location.");
    }
    
    server.addEndpoint(Endpoint {
        path = startsWith("/todo");
        service => demo;
    });
    
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
