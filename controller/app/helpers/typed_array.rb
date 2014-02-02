class TypedArray < Array
  def self.[](const)
    (@classes ||= {})[const] ||= Class.new(TypedArray) do
      @type = const

      def self.mongoize(object)
        case object
        when ::Array
          object.inject(new){ |a, o| a << @type.mongoize(o) }
        when Array
          map{ |o| @type.mongoize(o) }
        else
          object
        end
      end

      def self.demongoize(object)
        case object
        when ::Array
          object.inject(new){ |a, o| a << @type.demongoize(o) }
        else
          object
        end
      end

      def self.evolve(object)
        object
      end
    end
  end

  def mongoize
    self.class.mongoize(self)
  end
end