# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:not_started_planning_application) }

  it_behaves_like "Presentable" do
    let(:presented) { create(:planning_application) }
    let(:presenter) { described_class.new(view, presented) }
  end

  it_behaves_like "AssessmentTasksPresenter"

  describe "#status_tag" do
    context "when an application is in the invalidated state" do
      let(:planning_application) { create(:invalidated_planning_application) }

      it "shows invalid" do
        expect(presenter.status_tag).to include ">Invalid<"
      end
    end
  end

  describe "#validation_status" do
    context "when validation is complete" do
      let(:planning_application) do
        build(:planning_application, :in_assessment)
      end

      it "returns 'complete'" do
        expect(presenter.validation_status).to eq(:complete)
      end
    end

    context "when validation request is present" do
      let(:other_change_validation_request) do
        create(:other_change_validation_request)
      end

      let(:planning_application) do
        create(
          :planning_application,
          :not_started,
          other_change_validation_requests: [other_change_validation_request]
        )
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when fee is marked as valid" do
      let(:planning_application) do
        create(:planning_application, :not_started, valid_fee: true)
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when red line boundary is marked as valid" do
      let(:planning_application) do
        create(
          :planning_application,
          :not_started,
          valid_red_line_boundary: true
        )
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when constraints checked" do
      let(:planning_application) do
        create(:planning_application, :not_started, constraints_checked: true)
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when documents checked" do
      let(:planning_application) do
        create(:planning_application, :not_started, documents_missing: false)
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when document marked as valid" do
      let(:document) { create(:document, validated: true) }

      let(:planning_application) do
        create(:planning_application, :not_started, documents: [document])
      end

      it "returns 'in_progress'" do
        expect(presenter.validation_status).to eq(:in_progress)
      end
    end

    context "when validation not started" do
      let(:planning_application) do
        create(:planning_application, :not_started)
      end

      it "returns 'not_started'" do
        expect(presenter.validation_status).to eq(:not_started)
      end
    end
  end

  describe "#next_relevant_date_tag" do
    [
      [:not_started, "Expiry date: ", :expiry_date],
      [:determined, "Granted at: ", :determination_date],
      [:returned, "Returned at: ", :returned_at],
      [:withdrawn, "Withdrawn at: ", :withdrawn_at],
      [:closed, "Closed at: ", :closed_at]
    ].each do |state, label, date|
      context "when the application is #{state.to_s.humanize}" do
        let(:planning_application) { create("#{state}_planning_application") }

        it "shows the '#{date}' date" do
          date = planning_application.send(date)

          expect(presenter.next_relevant_date_tag).to include date.to_fs
        end

        it "shows a '#{label}' label" do
          expect(presenter.next_relevant_date_tag).to include label
        end
      end
    end
  end

  describe "#fee_related_proposal_details" do
    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{ value: "Answer 1" }],
          metadata: { portal_name: "Fee Related Group" }
        },
        {
          question: "Question 2",
          responses: [{ value: "Answer 2" }],
          metadata: { portal_name: "group-about-fee" }
        },
        {
          question: "Question 3",
          responses: [{ value: "Answer 3" }],
          metadata: { portal_name: "a_fee_group" }
        },
        {
          question: "Question 4",
          responses: [{ value: "Answer 4" }],
          metadata: { portal_name: "Other Group" }
        },
        {
          question: "Question 5",
          responses: [{ value: "Answer 5" }],
          metadata: { portal_name: "Birdfeed Related" }
        }
      ].to_json
    end

    let(:planning_application) do
      create(:planning_application, proposal_details:)
    end

    it "returns proposal details with 'fee' in the portal name" do
      expect(
        presenter.fee_related_proposal_details.map(&:portal_name)
      ).to contain_exactly(
        "Fee Related Group",
        "group-about-fee",
        "a_fee_group"
      )
    end
  end

  describe "#open_description_change_request" do
    let(:planning_application) { create(:planning_application) }

    context "when open description_change_validation_request present" do
      let!(:description_change_validation_request) do
        create(
          :description_change_validation_request,
          :open,
          planning_application:
        )
      end

      it "returns description_change_validation_request" do
        expect(
          planning_application.open_description_change_request
        ).to eq(
          description_change_validation_request
        )
      end
    end

    context "when no open description_change_validation_request present" do
      before do
        create(
          :description_change_validation_request,
          :closed,
          planning_application:
        )
      end

      it "returns nil" do
        expect(planning_application.open_description_change_request).to be_nil
      end
    end
  end

  describe "#multiple_policy_classes?" do
    let(:planning_application) { create(:planning_application) }
    let(:presenter) { described_class.new(view, planning_application) }

    before do
      create(:policy_class, planning_application:)
    end

    context "when there is a single policy class" do
      it "returns false" do
        expect(presenter.multiple_policy_classes?).to be(false)
      end
    end

    context "when there are multiple policy classes" do
      before do
        create(:policy_class, planning_application:)
      end

      it "returns true" do
        expect(presenter.multiple_policy_classes?).to be(true)
      end
    end
  end

  describe "#application_type_with_status" do
    let(:planning_application) { create(:planning_application) }
    let(:presenter) { described_class.new(view, planning_application) }

    context "when the status is proposed" do
      it "is reflected in the type" do
        expect(presenter.application_type_with_status).to include("LDC Proposed")
        expect(presenter.application_type_with_status).to include("Lawful Development Certificate Proposed")
      end
    end

    context "when the work status is existing" do
      it "is reflected in the type" do
        planning_application.work_status = "existing"
        expect(presenter.application_type_with_status).to include("LDC Existing")
        expect(presenter.application_type_with_status).to include("Lawful Development Certificate Existing")
      end
    end
  end
end
