# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailValidator do
  let(:errors) { subject.errors[:email] }

  let :model do
    Class.new do
      include ActiveModel::Model

      attr_accessor :email

      validates :email, email: true

      class << self
        def name
          "LocalAuthority"
        end
      end
    end
  end

  subject { model.new(email: email) }

  before do
    subject.valid?
  end

  describe "with a simple email address" do
    let(:email) { "laura@example.com" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end

  describe "with a subdomain email address" do
    let(:email) { "laura@subdomain.example.com" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end

  describe "with an email address on a new top-level domain" do
    let(:email) { "laura@example.photography" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end

  describe "with a single character email address" do
    let(:email) { "l@example.com" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end

  describe "with an email address without a domain" do
    let(:email) { "laura@example" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address without a local part" do
    let(:email) { "@example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address without an @ symbol" do
    let(:email) { "laura.example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing a space in the local part" do
    let(:email) { "laura @example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing a space in the domain part" do
    let(:email) { "laura@ example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing a space in the domain part" do
    let(:email) { "laura@ example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing an @ symbol in the local part" do
    let(:email) { "laura@home@example.com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing an @ symbol in the domain part" do
    let(:email) { "laura@example.@com" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with an email address containing a plus address part" do
    let(:email) { "laura+bops@example.com" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end
end
