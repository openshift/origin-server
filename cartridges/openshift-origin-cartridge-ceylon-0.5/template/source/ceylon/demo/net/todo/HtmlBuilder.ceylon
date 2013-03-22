by("Matej Lazar")

shared class HtmlBuilder(String path) {

    variable String body = "";

    shared String html {
        String html="<!DOCTYPE html>\n" +
                "<html lang=\"en\">\n" +
                "<head>\n" +
                "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n" +
                "<title>Ceylon ToDo List</title>\n" +
                "<link href=\"" +  path + "/css/bootstrap.min.css\" rel=\"stylesheet\">\n" +
                "<link href=\"" +  path + "/css/style.css\" rel=\"stylesheet\">\n" +
                "</head>\n" +
                "<body>\n" +
                "<script src=\"" +  path + "/js/bootstrap.min.js\"></script>\n" +
                "<div class=\"container\">\n" +
                body + "\n" +
                "</div>\n" +
                "</body>\n" +
                "</html>\n";
        return html;
    }

    shared void addToBody(String html) {
        body += html;
    }

}
