class EnumeratorArray < Enumerator
  delegate :<<, :delete_if, :compact, :length, :count, to: :to_a

  def +(other)
    to_a.concat(other)
  end
end