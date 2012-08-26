module Console
  module VERSION #:nocov:
    MAJOR = 1
    MINOR = 0
    MICRO = 0
    PRE  = 'alpha'
    STRING = [MAJOR,MINOR,MICRO,PRE].compact.join('.')
  end
end
