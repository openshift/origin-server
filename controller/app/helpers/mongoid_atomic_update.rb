module MongoidAtomicUpdate

  #
  # Given a block which mutates a single document, ensure all
  # operations are persisted in the same save and update call.
  #
  def atomic_update(&block)
    if persisted?
      _assigning(&block)
      @_children = nil
      save!
    else
      yield
    end
  end
end