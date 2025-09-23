# frozen_string_literal: true

FactoryBot.define do
  factory :site_notice do
    required { true }
    content { "This is a site notice" }
    quantity { 1 }
    planning_application
  end
end
