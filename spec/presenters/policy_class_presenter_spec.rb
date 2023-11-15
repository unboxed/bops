# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClassPresenter, type: :presenter do
  let(:presenter) { described_class.new(policy_class) }

  it_behaves_like "Presentable" do
    let(:presented) { create(:policy_class) }
    let(:presenter) { described_class.new(presented) }
  end

  describe "#default_path" do
    let(:planning_application) { create(:planning_application) }

    context "when status is 'complete'" do
      let(:policy_class) do
        create(
          :policy_class,
          :complete,
          planning_application:
        )
      end

      it "returns show path" do
        expect(
          presenter.default_path
        ).to eq(
          "/planning_applications/#{planning_application.id}/assessment/policy_classes/#{policy_class.id}"
        )
      end
    end

    context "when status is 'in_assessment'" do
      let(:policy_class) do
        create(
          :policy_class,
          :in_assessment,
          planning_application:
        )
      end

      it "returns edit path" do
        expect(
          presenter.default_path
        ).to eq(
          "/planning_applications/#{planning_application.id}/assessment/policy_classes/#{policy_class.id}/edit"
        )
      end
    end
  end

  describe "#previous" do
    let(:planning_application) { create(:planning_application) }

    let(:policy_class) do
      create(
        :policy_class,
        section: "B",
        planning_application:
      )
    end

    before do
      create(
        :policy_class,
        section: "A",
        planning_application:
      )
    end

    it "returns record wrapped in presenter" do
      expect(presenter.previous).to be_instance_of(described_class)
    end

    it "wraps previous record" do
      expect(presenter.previous.section).to eq("A")
    end
  end

  describe "#next" do
    let(:planning_application) { create(:planning_application) }

    let(:policy_class) do
      create(
        :policy_class,
        section: "A",
        planning_application:
      )
    end

    before do
      create(
        :policy_class,
        section: "B",
        planning_application:
      )
    end

    it "returns record wrapped in presenter" do
      expect(presenter.next).to be_instance_of(described_class)
    end

    it "wraps previous record" do
      expect(presenter.next.section).to eq("B")
    end
  end
end
