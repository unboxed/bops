# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrlValidator do
  let(:errors) { subject.errors[:link] }

  let :model do
    Class.new do
      include ActiveModel::Model
      attr_accessor :link

      validates :link, url: true

      class << self
        def name
          "Legislation"
        end
      end
    end
  end

  subject { model.new(link: url) }

  before do
    subject.valid?
  end

  describe "with a url of 'foo'" do
    let(:url) { "foo" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with a url of 'ftp://foo'" do
    let(:url) { "ftp://foo" }

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with a url of 'http://foo'" do
    let(:url) { "http://foo" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end

  describe "with a url of 'https://foo'" do
    let(:url) { "https://foo" }

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end
end
