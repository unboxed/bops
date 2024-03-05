# frozen_string_literal: true

class AddOwnerToValidationRequests < ActiveRecord::Migration[7.1]
  def up
    add_reference :validation_requests, :owner, index: true, polymorphic: true

    ValidationRequest.where(type: "PreCommencementConditionValidationRequest").find_each do |request|
      request.update!(owner_id: request.condition_id, owner_type: "Condition")
    end

    remove_reference :validation_requests, :condition
  end

  def down
    add_reference :validation_requests, :condition, null: true

    ValidationRequest.where(owner_type: "Condition").find_each do |request|
      request.update!(condition_id: request.owner_id)
    end

    change_table :validation_requests, bulk: true do |t|
      t.remove :owner_type
      t.remove :owner_id
    end
  end
end
