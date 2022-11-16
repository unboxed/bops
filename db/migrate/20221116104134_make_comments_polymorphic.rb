# frozen_string_literal: true

class MakeCommentsPolymorphic < ActiveRecord::Migration[6.1]
  def up
    change_table :comments, bulk: true do |t|
      t.references :commentable, polymorphic: true
    end

    execute(
      "UPDATE comments
      SET commentable_type = 'Policy', commentable_id = policy_id;"
    )

    change_table :comments, bulk: true do |t|
      t.remove :policy_id
    end
  end

  def down
    change_table :comments, bulk: true do |t|
      t.references :policy
    end

    execute("UPDATE comments SET policy_id = commentable_id;")

    change_table :comments, bulk: true do |t|
      t.remove :commentable_id
      t.remove :commentable_type
    end
  end
end
