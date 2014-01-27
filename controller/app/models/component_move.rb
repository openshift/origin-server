class ComponentMove
  def initialize(component, from, to)
    @component = component
    @from = from
    @to = to
  end

  def clean
    from.removed.delete(component)
    to.added.delete(component)
  end

  protected
    attr_reader :component, :from, :to
end