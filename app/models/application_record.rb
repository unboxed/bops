# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def update(attributes, context = nil)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end

  def update!(attributes, context = nil)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save!(context: context)
    end
  end
end
