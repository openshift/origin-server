by ("Matej Lazar")

shared interface Task {
    shared formal String id;
    shared formal String message;
    shared formal variable Boolean done;

}

class DefaultTask(message, id, done = false) satisfies Task {
    shared actual variable Boolean done;
    shared actual String id;
    shared actual String message;
}

String generateId() {
    return process.nanoseconds.string;
}

shared Task createTask(String message) {
    return DefaultTask(message, generateId());
}
