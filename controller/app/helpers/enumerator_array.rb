class EnumeratorArray < Enumerator
  delegate :<<, :delete_if, :compact, to: :to_a

  def +(other)
    to_a.concat(other)
  end
end