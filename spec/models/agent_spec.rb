# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Agent, type: :model do

  subject { FactoryBot.create :agent }

  it "should create agent successfully" do
    expect(subject).to be_valid
  end

  it "should create agent name as a string" do
    expect(subject.name).to be_a(String)
  end

  it "should create agent phone number as a string" do
    expect(subject.phone).to be_a(String)
  end

  it "should create agent phone number as a string" do
    expect(subject.email).to be_a(String)
  end
end
