import ceylon.net.httpd { HttpRequest, HttpResponse, HttpSession }

by "Matej Lazar"
shared abstract class WebBase() {
	
	shared void testOperations(HttpRequest request, HttpResponse response) {
		HttpSession session = request.session();
		
		value url = request.uri();
		response.addHeader("content-type", "text/html");
		response.writeString("Hello from ceylon web app. <br />\nRequested url: " url "<br />\n");
		response.writeString("TS: " process.milliseconds "<br />\n");

		if (exists foo = request.parameter("foo")) {
			response.writeString("Param foo:" foo "<br />\n");
		} else {
			response.writeString("Param foo NOT set.<br />\n");
		}
		
		if (exists bar = request.parameter("bar")) {
			response.writeString("Param bar:" bar "<br />\n");
		} else {
			response.writeString("Param bar NOT set.<br />\n");
		}
		
		Object? oPerson = session.item("pJN");

		if (is Person person = oPerson) {
			response.writeString("Person: " person.id() "");
		} else {
			Person p = Person();
			p.name = "Janez";
			p.surname = "Novak";
			session.put("pJN", p);
			response.writeString("Person stored to session. Refresh page to read it from session.");
		}
		
	}

	class Person() {
		shared variable String name = "";
		shared variable String surname = "";
		
		shared String id() {
			return name + " " + surname;
		}
	}
}