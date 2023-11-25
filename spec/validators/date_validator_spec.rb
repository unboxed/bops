# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateValidator do
  let(:validation_context) { nil }
  let(:errors) { subject.errors[:consultation_date] }
  let(:before_type_cast) { subject.consultation_date_before_type_cast }

  let(:attributes) do
    {consultation_date: date}
  end

  let :base do
    Class.new(ApplicationRecord) do
      include DateValidateable

      attribute :consultation_date, :date

      class << self
        def name
          "Consultation"
        end
      end
    end
  end

  subject { model.new(attributes) }

  before do
    subject.valid?(validation_context)
  end

  describe "validating the date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: true
      end
    end

    context "when the date is nil" do
      let(:date) { nil }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is a valid date object" do
      let(:date) { Date.civil(2023, 11, 25) }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is a valid time object" do
      let(:date) { Time.utc(2023, 11, 25) }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is a valid string" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is an invalid string" do
      let(:date) { "2023-13-25" }

      it "adds an error" do
        expect(errors).to match ["is not a valid date"]
      end

      it "returns a string for the before type cast value" do
        expect(before_type_cast).to eq("2023-13-25")
      end
    end

    context "when the date is an invalid multiparameter assignment" do
      let(:attributes) do
        {
          "consultation_date(3i)" => "25",
          "consultation_date(2i)" => "13",
          "consultation_date(1i)" => "2023"
        }
      end

      it "adds an error" do
        expect(errors).to match ["is not a valid date"]
      end

      it "returns a date-like object for the before type cast value" do
        expect(before_type_cast).to have_attributes(day: 25, month: 13, year: 2023)
      end
    end
  end

  describe "validating the date is present" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {presence: true}
      end
    end

    context "when the date is present" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "adds an error" do
        expect(errors).to match ["is blank"]
      end
    end
  end

  describe "validating the date is present" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {presence: true}
      end
    end

    context "when the date is present" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "adds an error" do
        expect(errors).to match ["is blank"]
      end
    end
  end

  describe "validating the date is a specific date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {is: "2023-11-25"}
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-26" }

      it "adds an error" do
        expect(errors).to match ["is not 25/11/2023"]
      end
    end
  end

  describe "validating the date is before specific date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {before: "2023-11-25"}
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-24" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-25" }

      it "adds an error" do
        expect(errors).to match ["is not before 25/11/2023"]
      end
    end
  end

  describe "validating the date is after specific date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {after: "2023-11-25"}
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-26" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-25" }

      it "adds an error" do
        expect(errors).to match ["is not after 25/11/2023"]
      end
    end
  end

  describe "validating the date is on or before specific date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {on_or_before: ->(c) { Date.civil(2023, 11, 25) }}
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-26" }

      it "adds an error" do
        expect(errors).to match ["is not on or before 25/11/2023"]
      end
    end
  end

  describe "validating the date is on or after specific date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {on_or_after: ->(c) { Date.civil(2023, 11, 25) }}
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-24" }

      it "adds an error" do
        expect(errors).to match ["is not on or after 25/11/2023"]
      end
    end
  end

  describe "validating the date is between specific dates" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {between: :date_range}

        def date_range
          Date.civil(2023, 11, 20)..Date.civil(2023, 11, 26)
        end
      end
    end

    context "when the date is not present" do
      let(:date) { "" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and valid" do
      let(:date) { "2023-11-25" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    context "when the date is present and before the range" do
      let(:date) { "2023-11-19" }

      it "adds an error" do
        expect(errors).to match ["is not between 20/11/2023 and 26/11/2023"]
      end
    end

    context "when the date is present and after the range" do
      let(:date) { "2023-11-27" }

      it "adds an error" do
        expect(errors).to match ["is not between 20/11/2023 and 26/11/2023"]
      end
    end
  end

  describe "formatting the date" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {is: "2023-11-25", format: "%m/%d/%Y"}
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-24" }

      it "adds an error with the correctly formatted date" do
        expect(errors).to match ["is not 11/25/2023"]
      end
    end
  end

  describe "customising the message" do
    let(:model) do
      Class.new(base) do
        validates :consultation_date, date: {after: "2023-11-25", message: "must be in the future"}
      end
    end

    context "when the date is present and invalid" do
      let(:date) { "2023-11-25" }

      it "adds an error with the custom message" do
        expect(errors).to match ["must be in the future"]
      end
    end
  end
end
