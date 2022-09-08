class AddStatusToPolicyClasses < ActiveRecord::Migration[6.1]
  def up
    add_column :policy_classes, :status, :integer

    execute(
      "UPDATE policy_classes
      SET status = 0
      FROM policies
      WHERE policies.policy_class_id = policy_classes.id
      AND policies.status = 2;"
    )

    execute(
      "UPDATE policy_classes
      SET status = 1
      WHERE status IS NULL;"
    )

    change_column_null :policy_classes, :status, false
  end

  def down
    remove_column :policy_classes, :status
  end
end
