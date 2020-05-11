# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Agent, type: :model do
  subject { FactoryBot.create :agent }

  it "should create agent successfully" do
    expect(subject).to be_valid
  end

  it "should create agent first name as a string" do
    expect(subject.first_name).to be_a(String)
  end

  it "should create agent last name as a string" do
    expect(subject.last_name).to be_a(String)
  end

  it "should create agent phone number as a string" do
    expect(subject.phone).to be_a(String)
  end

  it "should create agent phone number as a string" do
    expect(subject.email).to be_a(String)
  end

  it "should create agent town as a string" do
    expect(subject.town).to be_a(String)
  end

  it "should create agent postcode as a string" do
    expect(subject.postcode).to be_a(String)
  end
end
