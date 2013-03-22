import ceylon.net.http.server { Session }
import ceylon.demo.net.todo.domain { Task }
import ceylon.collection { MutableMap, HashMap }

by ("Matej Lazar")
shared class TaskDAO(Session session) {

    shared void addTask(Task task) {
        taskMap.put(task.id, task);
    }

    shared Collection<Task> tasks(String q = "") {
        if (q.empty) {
            return taskMap.values;
        } else {
            return queryTasks(q).collect((String->Task element) => element.item);
        }
    }

    shared void taskDone(String id, Boolean done) {
        Task task = taskById(id);
        task.done = done;
    }

    
    Task taskById(String id) {
        Task? task = taskMap.get(id);
        if (exists task) {
            return task;
        } else {
            throw Exception("Invalid id");
        }
    }

    shared void delete(String id) {
        taskMap.remove(id);
    }

    MutableMap<String, Task> initTasks() {
        MutableMap<String, Task> tasks = HashMap<String, Task>();
        session.put("tasks", tasks);
        return tasks;
    }

    MutableMap<String, Task> taskMap {
        Object? taskList = session.get("tasks");
        if (exists taskList) {
            if (is MutableMap<String, Task> t = taskList) {
                return t;
            }
            throw Exception("Invalid object storrd in sesion.");
        } else {
            return initTasks();
        }
    }

    {<String->Task>*} queryTasks(String q) {
        return taskMap.filter((String->Task elem) => elem.item.message.contains(q));
    }
}
