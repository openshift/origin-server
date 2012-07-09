require 'thread'

module ThreadDumper
  DUMP_SEPARATOR = "=" * 80
  class Dumper
    def self.dump_thread_backtraces(fmt=nil)
      dump = ""
      Thread.list.each do |t|
        dump += "#{DUMP_SEPARATOR}\n"
        dump += "<br /><h3>\n" if fmt == 'html'
        dump += "Thread #{t.object_id}: #{t.to_s} - #{t.group}, pri=#{t.priority}\n"
        dump += "</h3><pre>\n" if fmt == 'html'
        dump += t.backtrace.join("\n") + "\n" if t.alive?
        dump += "</pre><br />\n" if fmt == 'html'
      end
      dump
    end
  end
end

trap 'QUIT' do
  btraces = ThreadDumper::Dumper.dump_thread_backtraces
  Thread.start do
    STDERR.write(btraces)
  end
end
