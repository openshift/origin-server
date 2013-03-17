import ceylon.net.http.server { Response, Request, Session}
import ceylon.net.http { contentType }
import ceylon.io.charset { utf8 }

by "Matej Lazar"
class Web() {

    shared void service(Request request, Response response) {
        Session session = request.session;
        
        value url = request.uri;
        response.addHeader(contentType { contentType = "text/html"; charset = utf8; });
        response.writeString("received header Content-Type: ``request.header("Content-Type") else "NOT SET"``<br />\n");
        response.writeString("Hello from ceylon web app. <br />\nRequested url: " + url + "<br />\n");
        response.writeString("TS: " + process.milliseconds.string + "<br />\n");
        
        if (exists foo = request.parameter("foo")) {
            response.writeString("Param foo:" + foo + "<br />\n");
        } else {
            response.writeString("Param foo NOT set.<br />\n");
        }
        
        if (exists bar = request.parameter("bar")) {
            response.writeString("Param bar:" + bar + "<br />\n");
        } else {
            response.writeString("Param bar NOT set.<br />\n");
        }
        
        Object? oPerson = session.get("pJN");
        
        if (is Person person = oPerson) {
            response.writeString("Person: ``person``");
        } else {
            Person p = Person();
            p.name = "Janez";
            p.surname = "Novak";
            p.message = "V kožuščku hudobnega fanta stopiclja mizar.";
            session.put("pJN", p);
            response.writeString("Person stored to session. Refresh page to read it from session.");
        }
    }
}

class Person() {
    shared variable String name = "";
    shared variable String surname = "";
    shared variable String message = "";
    shared actual String string {
        return "``name`` ``surname``: ``message``";
    }
}

