# frozen_string_literal: true

class ApplicationTypeOverrides
  include StoreModel::Model

  attribute :code, :string
  attribute :determination_period_days, :integer

  validates :determination_period_days, presence: true
  validates :determination_period_days, numericality: {only_integer: true}
  validates :determination_period_days, numericality: {greater_than_or_equal_to: 1}
  validates :determination_period_days, numericality: {less_than_or_equal_to: 99}
end
