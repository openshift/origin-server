class GroupChange
  def self.moves(changes)
    moves = []

    changes.each do |from|
      from.removed.each do |component|
        changes.each do |to|
          next if from == to
          if to.added.include?(component)
            moves << ComponentMove.new(component, from, to)
          end
        end
      end
    end
    moves.each(&:clean)
  end

  attr_reader :to, :from, :upgrades

  # Expects a GroupInstance and a GroupOverride
  def initialize(from, to, upgrades={})
    @from = from
    @to = to
    @upgrades = upgrades
  end

  def new?
    from.nil?
  end

  def existing?
    !new?
  end

  def delete?
    to.nil?
  end

  def upgraded?
    upgraded.present?
  end

  def removed?
    removed.present?
  end

  def added?
    added.present?
  end

  def upgraded
    @upgraded ||= begin
      if to && from
        to.components.map do |t|
          if (original = from.components.find{ |f| f == t }) && !t.version_equal?(original)
            [original, t]
          end
        end.compact.concat(@upgrades.each_pair.to_a)
      else
        @upgrades.each_pair.to_a
      end
    end
  end

  def removed
    @removed ||= begin
      if from
        changing = from.components.map{ |c| @upgrades[c] || c }
        if to
          changing - to.components
        else
          changing
        end
      end || []
    end
  end

  def added
    @added ||= begin
      if from
        if to
          to.components - from.components.map{ |c| @upgrades[c] || c }
        end
      elsif to
        to.components.dup
      end || []
    end
  end

  def gear_change
    @gear_change ||= to_gears - from_gears
  end

  def additional_filesystem_change
    @additional_filesystem_change ||= (to ? to.additional_filesystem_gb : 0) - (from ? from.additional_filesystem_gb : 0)
  end

  def to_instance_id
    @new_instance_id ||= Moped::BSON::ObjectId.new
  end

  def existing_instance_id
    from.instance._id
  end

  def will_have_app_dns?(application)
    if application.scalable
      added.any?{ |c| c.cartridge.is_web_proxy? }
    else
      added.any?{ |c| c.cartridge.is_web_framework? }
    end
  end

  protected
    def to_gears
      @to_gear_upper ||=
        if to
          if to.max_gears == -1
            [from_gears, to.min_gears].max
          else
            [
              [from_gears, to.max_gears].min,
              to.min_gears
            ].max
          end
        else
          0
        end
    end

    def from_gears
      @from_gears ||= (from ? from.instance.gears.length : 0)
    end

      # from_id = nil
      # from_comp_insts = []
      # to_comp_insts   = []
      # from_scale      = {min: 1, max: MAX_SCALE, current: 0, additional_filesystem_gb: 0, gear_size: self.default_gear_size}
      # to_scale        = {min: 1, max: MAX_SCALE}

      # unless current_group_instances[from].nil?
      #   from_comp_insts = current_group_instances[from][:component_instances]
      #   from_id         = current_group_instances[from][:_id]
      #   from_scale      = current_group_instances[from][:scale]
      # end

      # unless new_group_instances[to].nil?
      #   to_comp_insts = new_group_instances[to][:component_instances]
      #   to_scale      = new_group_instances[to][:scale]
      #   to_id         = from_id || new_group_instances[to][:_id]
      # end
      # unless from_comp_insts.empty? and to_comp_insts.empty?
      #   added, removed = compute_comp_inst_diffs(from_comp_insts, to_comp_insts)
      #   changes << {from: from_id, to: to_id, added: added, removed: removed, from_scale: from_scale, to_scale: to_scale}
      # end

end