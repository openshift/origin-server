module PreAndPostCondition
  def pre_and_post_condition(pre, post, run, fails)
    return false if !pre.call
    run.call
    if post.call
      true
    else
      fails.call
      false
    end
  end
end