# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Drawing, type: :model do
  subject { FactoryBot.create :drawing, :with_plan }

  it "should create attached plan successfully" do
    expect(subject).to be_valid
  end

  it "should create attached plan successfully" do
    expect(subject).to be_valid
  end

  it "should be able to be archived with valid reason" do
    subject.archive("scale")
    expect(subject.archived_at).not_to be(nil)
  end

  it "should return true when archived? method called" do
    subject.archive("scale")
    expect(subject.is_archived?).to be true
  end
end
