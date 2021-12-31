# frozen_string_literal: true

class MakeAssessorIdOptional < ActiveRecord::Migration[6.1]
  def change
    change_table :recommendations do |t|
      t.change_null :assessor_id, true
    end
  end
end
