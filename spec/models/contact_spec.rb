# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contact do
  describe "#valid?" do
    let(:contact) { build(:contact) }

    it "is true for the default factory" do
      expect(contact.valid?).to be(true)
    end

    context "when the name is missing" do
      let(:contact) { build(:contact, name: nil) }

      it "is false" do
        expect(contact.valid?).to be(false)
        expect(contact.errors).to be_added(:name, :blank)
      end
    end

    context "when the origin is not in the list of accepted values" do
      let(:contact) { build(:contact, origin: "invalid") }

      it "is false" do
        expect(contact.valid?).to be(false)
        expect(contact.errors).to be_added(:origin, :inclusion, value: "invalid")
      end
    end

    context "when the category is not in the list of accepted values" do
      let(:contact) { build(:contact, category: "invalid") }

      it "is false" do
        expect(contact.valid?).to be(false)
        expect(contact.errors).to be_added(:category, :inclusion, value: "invalid")
      end
    end
  end

  describe ".search" do
    let(:lambeth) { create(:local_authority, :lambeth) }
    let(:southwark) { create(:local_authority, :southwark) }

    before do
      create(:contact, :internal, local_authority: lambeth, name: "Theresa Green", role: "Tree Officer")
      create(:contact, :internal, local_authority: southwark, name: "Dirk Wood", role: "Tree Officer")
      create(:contact, :external, name: "Sam Shepard", role: "Fire Safety Officer", organisation: "London Fire Brigade")
    end

    it "searches on the name" do
      expect(described_class.search("Shepard")).to match_array [
        an_object_having_attributes(name: "Sam Shepard")
      ]
    end

    it "searches on the role" do
      expect(described_class.search("Safety")).to match_array [
        an_object_having_attributes(name: "Sam Shepard")
      ]
    end

    it "searches on the organisation" do
      expect(described_class.search("Brigade")).to match_array [
        an_object_having_attributes(name: "Sam Shepard")
      ]
    end

    it "searches on a prefix" do
      expect(described_class.search("Safe")).to match_array [
        an_object_having_attributes(name: "Sam Shepard")
      ]
    end

    context "when no local authority is specified" do
      let(:options) do
        { category: "consultee" }
      end

      it "returns only external consultees" do
        expect(described_class.search("Officer", **options)).to match_array [
          an_object_having_attributes(name: "Sam Shepard")
        ]
      end
    end

    context "when the local authority is specified" do
      let(:options) do
        { category: "consultee", local_authority: lambeth }
      end

      it "returns internal and external contacts" do
        expect(described_class.search("Officer", **options)).to match_array [
          an_object_having_attributes(name: "Sam Shepard"),
          an_object_having_attributes(name: "Theresa Green")
        ]
      end
    end
  end
end
