# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Document, type: :model do
  subject { FactoryBot.create :document, :with_plan }

  it "should create attached plan successfully" do
    expect(subject).to be_valid
  end
end
