import ceylon.demo.net.todo.domain { Task }

by("Matej Lazar")

shared String inputForm(String q) {
    return "<form method=\"GET\">\n" +
            "<label>New Task</label>\n" +
            "<div class=\"input-append\">\n" +
            "<input type=\"text\" name=\"message\" placeholder=\"Enter new task ...\"/>\n" +
            "<button type=\"submit\" class=\"btn\">Add</button>\n" +
            "</div>\n" +
            "<div class=\"input-append\">\n" +
            "<label>Filter</label>\n" +
            "<input type=\"text\" name=\"q\" value=\""+ q + "\"/>\n" +
            "<button type=\"submit\" class=\"btn\">Apply</button>\n" +
            "<button type=\"submit\" class=\"btn\" onclick=\"this.form.q.value='';this.form.sumit();\">Remove</button>\n" +
            "</div>\n" +
            "</form>\n";
}

shared String taksList(Collection<Task> tasks, String q) {
    variable String html = "\n";
    html += "<table class=\"table table-hover\">\n";

    for (Task task in tasks) {
        String onClickDone="onclick=\"document.location='?q=" + q + "&" + (task.done then "markNotDone" else "markDone") + "=" + task.id + "'\"";
        String onClickRemove="onclick=\"document.location='?q=" + q + "&remove=" + task.id + "'\"";

        html += "<tr>\n";
        html += "<td>\n";
        html += "<label class=\"checkbox\">\n";
        html += "<input type=\"checkbox\"" + (task.done then "checked=\"checked\"" else "");
        html += " " + onClickDone + "/>\n";
        html += "<span class=\"" + (task.done then "taskDone" else "taskNotDone") + "\">" +  task.message + "</span>\n";
        html += "</label>\n";
        html += "</td>\n";
        html += "<td width=\"20px\">\n";
        html += "<i class=\"icon-remove\" " + onClickRemove + "/>\n";
        html += "</td>\n";
        html += "</tr>\n";
    }
    html += "</table>\n";
    html += "\n";
    return html;
}

shared String title(String title) {
    return "<h1>" + title + "</h1>";
}
