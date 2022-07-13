# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "DateValidateable" do
  before do
    subject.attributes = params
    subject.valid?
  end

  context "when params are valid" do
    let(:params) do
      {
        "#{attribute}_day" => "1",
        "#{attribute}_month" => "6",
        "#{attribute}_year" => "2022"
      }
    end

    it "sets attribute day" do
      expect(subject.send("#{attribute}_day")).to eq("1")
    end

    it "sets attribute month" do
      expect(subject.send("#{attribute}_month")).to eq("6")
    end

    it "sets attribute year" do
      expect(subject.send("#{attribute}_year")).to eq("2022")
    end

    it "has no errors" do
      expect(subject.errors.messages).to be_empty
    end

    it "sets attribute" do
      expect(subject.send(attribute).to_date).to eq(Date.new(2022, 6, 1))
    end
  end

  context "when all params are blank" do
    let(:params) do
      {
        "#{attribute}_day" => "",
        "#{attribute}_month" => "",
        "#{attribute}_year" => ""
      }
    end

    it "sets attribute day" do
      expect(subject.send("#{attribute}_day")).to eq("")
    end

    it "sets attribute month" do
      expect(subject.send("#{attribute}_month")).to eq("")
    end

    it "sets attribute year" do
      expect(subject.send("#{attribute}_year")).to eq("")
    end

    it "has no errors" do
      expect(subject.errors.messages).to be_empty
    end

    it "does not set attribute" do
      expect(subject.send(attribute)).to eq(nil)
    end
  end

  context "when a value is missing" do
    let(:params) do
      {
        "#{attribute}_day" => "1",
        "#{attribute}_month" => "",
        "#{attribute}_year" => "2022"
      }
    end

    it "sets attribute day" do
      expect(subject.send("#{attribute}_day")).to eq("1")
    end

    it "sets attribute month" do
      expect(subject.send("#{attribute}_month")).to eq("")
    end

    it "sets attribute year" do
      expect(subject.send("#{attribute}_year")).to eq("2022")
    end

    it "has error message" do
      expect(
        subject.errors.messages[attribute]
      ).to contain_exactly(
        "is invalid"
      )
    end

    it "does not set attribute" do
      expect(subject.send(attribute)).to eq(nil)
    end
  end

  context "when a value is not a date" do
    let(:params) do
      {
        "#{attribute}_day" => "1",
        "#{attribute}_month" => "100",
        "#{attribute}_year" => "2022"
      }
    end

    it "sets attribute day" do
      expect(subject.send("#{attribute}_day")).to eq("1")
    end

    it "sets attribute month" do
      expect(subject.send("#{attribute}_month")).to eq("100")
    end

    it "sets attribute year" do
      expect(subject.send("#{attribute}_year")).to eq("2022")
    end

    it "has error message" do
      expect(
        subject.errors.messages[attribute]
      ).to contain_exactly(
        "is invalid"
      )
    end

    it "does not set attribute" do
      expect(subject.send(attribute)).to eq(nil)
    end
  end

  context "when a value is not numeric" do
    let(:params) do
      {
        "#{attribute}_day" => "1",
        "#{attribute}_month" => "abc",
        "#{attribute}_year" => "2022"
      }
    end

    it "sets attribute day" do
      expect(subject.send("#{attribute}_day")).to eq("1")
    end

    it "sets attribute month" do
      expect(subject.send("#{attribute}_month")).to eq("abc")
    end

    it "sets attribute year" do
      expect(subject.send("#{attribute}_year")).to eq("2022")
    end

    it "has error message" do
      expect(
        subject.errors.messages[attribute]
      ).to contain_exactly(
        "is invalid"
      )
    end

    it "does not set attribute" do
      expect(subject.send(attribute)).to eq(nil)
    end
  end
end
