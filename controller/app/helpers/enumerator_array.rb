class EnumeratorArray < Enumerator
  delegate :<<, :delete_if, :compact, :length, :count, :concat, to: :to_a

  def +(other)
    to_a.concat(other)
  end

  def to_ary
    to_a
  end
end