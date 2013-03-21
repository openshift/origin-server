import ceylon.net.http.server { Request }
import ceylon.net.http.server { Response }
import ceylon.file { Path, File, parsePath }
import ceylon.io { newOpenFile }
import ceylon.net.http { contentLength, contentType }
import ceylon.io.charset { utf8 }
import ceylon.io.buffer { ByteBuffer, newByteBuffer }


by ("Matej Lazar")
shared void welcomePage(String pathToFile)(Request request, Response response) {
    Path filePath = parsePath(pathToFile);
    if (is File file = filePath.resource) {
        value openFile = newOpenFile(file);
        try {
            Integer available = file.size;
            
            response.addHeader(contentLength(available.string));
            response.addHeader(contentType { 
                                    contentType = "text/html"; 
                                    charset = utf8; 
                               });
            
            /* Simple file read and write to response. 
               As we have no parsing/content modification we should use
               channels to transfer bytes efficiently. */
            ByteBuffer buffer = newByteBuffer(available);
            openFile.read(buffer);
            response.writeBytes(buffer.bytes());
        } finally {
            openFile.close();
        }
    } else {
        response.responseStatus=404;
    }
}
