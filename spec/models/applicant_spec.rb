# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Applicant, type: :model do
  subject { FactoryBot.create :applicant }

  it "should create applicant successfully" do
    expect(subject).to be_valid
  end

  it "should create applicant name as a string" do
    expect(subject.name).to be_a(String)
  end

  it "should create applicant phone number as a string" do
    expect(subject.phone).to be_a(String)
  end

  it "should create applicant phone number as a string" do
    expect(subject.email).to be_a(String)
  end
end
