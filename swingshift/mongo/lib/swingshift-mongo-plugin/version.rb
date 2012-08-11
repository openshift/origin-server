module SwingShift
 VERSION = File.open("#{File.dirname(__FILE__)}/../../swingshift-mongo-plugin.spec"
                      ).readlines.delete_if{ |x| !x.match(/Version:/)
                      }.first.split(':')[1].strip
end
