module Console
  class ConfigFile < HashWithIndifferentAccess
    def initialize(file)
      IO.read(File.expand_path(file)).lines.
        map{ |s| s.gsub(/((^|[^\\])(\\\\)*)#.*/,'\1') }. # eliminate unescaped comments
        each do |s|
          if pair = /^\s*(.*?[^\\]+?(?:\\\\)*)=(.*)$/.match(s)
            self[pair[1].strip.gsub(/\\(.)/,'\1')] = pair[2].strip.gsub(/\\(.)/,'\1')
          end
        end
    end
  end
end
