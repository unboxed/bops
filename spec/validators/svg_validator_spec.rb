# frozen_string_literal: true

require "rails_helper"

RSpec.describe SvgValidator do
  let(:errors) { subject.errors[:logo] }

  let :model do
    Class.new do
      include ActiveModel::Model

      attr_accessor :logo

      validates :logo, svg: true

      class << self
        def name
          "LocalAuthority"
        end
      end
    end
  end

  subject { model.new(logo: svg) }

  before do
    subject.valid?
  end

  describe "with an invalid svg document" do
    let(:svg) do
      <<~SVG
        <svg>
          <circle cx="50" cy="50" r="50" />
        </svg>
      SVG
    end

    it "adds an error" do
      expect(errors).to include("is invalid")
    end
  end

  describe "with a valid svg document'" do
    let(:svg) do
      <<~SVG
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <circle cx="50" cy="50" r="50" />
        </svg>
      SVG
    end

    it "doesn't add an error" do
      expect(errors).to be_empty
    end
  end
end
