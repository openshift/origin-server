import ceylon.net.http.server { Response, Request, Session}
import ceylon.net.http { contentType }
import ceylon.io.charset { utf8 }
import ceylon.demo.net.todo.dao { TaskDAO }
import ceylon.demo.net.todo.domain { createTask }

by "Matej Lazar"

shared void demo(Request request, Response response) {
    Session session = request.session;
    
    response.addHeader(contentType { contentType = "text/html"; charset = utf8; });

    TaskDAO tasksDAO = TaskDAO(session);

    String q = request.parameter("q") else "";

    String? message = request.parameter("message");
    String? markDone = request.parameter("markDone");
    String? markNotDone = request.parameter("markNotDone");
    String? remove = request.parameter("remove");

    if (exists message, !message.empty) {
        tasksDAO.addTask(createTask(message));
    }

    if (exists markDone, !markDone.empty) {
        tasksDAO.taskDone(markDone, true);
    }

    if (exists markNotDone, !markNotDone.empty) {
        tasksDAO.taskDone(markNotDone, false);
    }

    if (exists remove, !remove.empty) {
        tasksDAO.delete(remove);
    }

    HtmlBuilder htmlPage = HtmlBuilder("");
    htmlPage.addToBody(title("Ceylon In Session ToDo List"));
    htmlPage.addToBody(inputForm(q));
    htmlPage.addToBody(taksList(tasksDAO.tasks(q), q));

    response.writeString(htmlPage.html);
}
