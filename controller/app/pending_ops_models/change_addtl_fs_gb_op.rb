class ChangeAddtlFsGbOp < PendingAppOp

  field :group_instance_id, type: Moped::BSON::ObjectId
  field :addtl_fs_gb, type: Integer
  field :saved_addtl_fs_gb, type: Integer

  def execute
    get_group_instance.tap{ |i| i.addtl_fs_gb = addtl_fs_gb }.save!
  end

  def rollback
    get_group_instance.tap{ |i| i.addtl_fs_gb = saved_addtl_fs_gb }.save!
  end
end
