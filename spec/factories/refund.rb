# frozen_string_literal: true

FactoryBot.define do
  factory :refund do
    planning_application
    payment_type { "BACS" }
    reason { "Overpayment" }
    reference { "REF111" }
    amount { 100.00 }
    date { Time.zone.today }
  end
end
