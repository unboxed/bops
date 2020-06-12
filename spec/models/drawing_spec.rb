# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Drawing, type: :model do
  subject { FactoryBot.create :drawing, :with_plan }

  it "should create attached plan successfully" do
    expect(subject).to be_valid
  end
end
