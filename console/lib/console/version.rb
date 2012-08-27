module Console
  module VERSION #:nocov:
    MAJOR = 0
    MINOR = 0
    MICRO = 1
    PRE  = nil
    STRING = [MAJOR,MINOR,MICRO,PRE].compact.join('.')
  end
end
