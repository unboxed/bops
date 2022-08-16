# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationPresenter, type: :presenter do
  include ActionView::TestCase::Behavior

  subject(:presenter) { described_class.new(view, planning_application) }

  let(:context) { ActionView::Base.new }
  let!(:planning_application) { create(:not_started_planning_application) }

  it "delegates missing methods to its application" do
    expect(presenter.id).to eq planning_application.id
  end

  it "advertises the methods it responds to" do
    expect(presenter).to respond_to :id
  end

  describe "#status_tag" do
    context "when an application is in the invalidated state" do
      let(:planning_application) { create(:invalidated_planning_application) }

      it "shows invalid" do
        expect(presenter.status_tag).to include ">Invalid<"
      end
    end
  end

  describe "#validation_status_tag" do
    context "when validation is complete" do
      let(:planning_application) do
        build(:planning_application, :in_assessment)
      end

      it "returns 'complete' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">Complete</span>"
        )
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

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
      end
    end

    context "when fee is marked as valid" do
      let(:planning_application) do
        create(:planning_application, :not_started, valid_fee: true)
      end

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
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

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
      end
    end

    context "when constraints checked" do
      let(:planning_application) do
        create(:planning_application, :not_started, constraints_checked: true)
      end

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
      end
    end

    context "when documents checked" do
      let(:planning_application) do
        create(:planning_application, :not_started, documents_missing: false)
      end

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
      end
    end

    context "when document marked as validt" do
      let(:document) { create(:document, validated: true) }

      let(:planning_application) do
        create(:planning_application, :not_started, documents: [document])
      end

      it "returns 'in progress' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--blue\">In progress</span>"
        )
      end
    end

    context "when validation not started" do
      let(:planning_application) do
        create(:planning_application, :not_started)
      end

      it "returns 'not started' tag" do
        expect(
          presenter.validation_status_tag
        ).to eq(
          "<span class=\"govuk-tag govuk-tag--grey\">Not started</span>"
        )
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

          expect(presenter.next_relevant_date_tag).to include date.to_s
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
      create(:planning_application, proposal_details: proposal_details)
    end

    it "returns proposal details with 'fee' in the portal name" do
      expect(presenter.fee_related_proposal_details).to eq(
        [
          OpenStruct.new(
            {
              question: "Question 1",
              responses: [OpenStruct.new({ value: "Answer 1" })],
              metadata: OpenStruct.new({ portal_name: "Fee Related Group" })
            }
          ),
          OpenStruct.new(
            {
              question: "Question 2",
              responses: [OpenStruct.new({ value: "Answer 2" })],
              metadata: OpenStruct.new({ portal_name: "group-about-fee" })
            }
          ),
          OpenStruct.new(
            {
              question: "Question 3",
              responses: [OpenStruct.new({ value: "Answer 3" })],
              metadata: OpenStruct.new({ portal_name: "a_fee_group" })
            }
          )
        ]
      )
    end
  end

  describe "#filtered_proposal_detail_groups_with_numbers" do
    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{ value: "Answer 1" }],
          metadata: { portal_name: "Group A", auto_answered: true }
        },
        {
          question: "Question 2",
          responses: [{ value: "Answer 2" }],
          metadata: { portal_name: "Group A" }
        },
        {
          question: "Question 3",
          responses: [{ value: "Answer 3" }],
          metadata: { portal_name: "Group B", auto_answered: true }
        },
        {
          question: "Question 4",
          responses: [{ value: "Answer 4" }],
          metadata: { portal_name: "Group C" }
        }
      ].to_json
    end

    let(:planning_application) do
      create(:planning_application, proposal_details: proposal_details)
    end

    it "returns numbered proposal details grouped by portal name" do
      expect(presenter.filtered_proposal_detail_groups_with_numbers).to eq(
        [
          OpenStruct.new(
            portal_name: "Group A",
            proposal_details: [
              OpenStruct.new(
                question: "Question 1",
                responses: [OpenStruct.new(value: "Answer 1")],
                metadata: OpenStruct.new(
                  portal_name: "Group A",
                  auto_answered: true
                ),
                number: 1
              ),
              OpenStruct.new(
                question: "Question 2",
                responses: [OpenStruct.new(value: "Answer 2")],
                metadata: OpenStruct.new(portal_name: "Group A"),
                number: 2
              )
            ]
          ),
          OpenStruct.new(
            portal_name: "Group B",
            proposal_details: [
              OpenStruct.new(
                question: "Question 3",
                responses: [OpenStruct.new(value: "Answer 3")],
                metadata: OpenStruct.new(
                  portal_name: "Group B",
                  auto_answered: true
                ),
                number: 3
              )
            ]
          ),
          OpenStruct.new(
            portal_name: "Group C",
            proposal_details: [
              OpenStruct.new(
                question: "Question 4",
                responses: [OpenStruct.new(value: "Answer 4")],
                metadata: OpenStruct.new(portal_name: "Group C"),
                number: 4
              )
            ]
          )
        ]
      )
    end

    context "when hide_auto_answered_proposal_details is true" do
      before { presenter.hide_auto_answered_proposal_details = true }

      it "excludes auto answered proposal details" do
        expect(presenter.filtered_proposal_detail_groups_with_numbers).to eq(
          [
            OpenStruct.new(
              portal_name: "Group A",
              proposal_details: [
                OpenStruct.new(
                  question: "Question 2",
                  responses: [OpenStruct.new(value: "Answer 2")],
                  metadata: OpenStruct.new(portal_name: "Group A"),
                  number: 2
                )
              ]
            ),
            OpenStruct.new(
              portal_name: "Group C",
              proposal_details: [
                OpenStruct.new(
                  question: "Question 4",
                  responses: [OpenStruct.new(value: "Answer 4")],
                  metadata: OpenStruct.new(portal_name: "Group C"),
                  number: 4
                )
              ]
            )
          ]
        )
      end
    end
  end

  describe "#open_description_change_request" do
    let(:planning_application) { create(:planning_application) }

    context "when open description_change_validation_request present" do
      let!(:description_change_validation_request) do
        create(
          :description_change_validation_request,
          :open,
          planning_application: planning_application
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
          planning_application: planning_application
        )
      end

      it "returns nil" do
        expect(planning_application.open_description_change_request).to eq(nil)
      end
    end
  end
end
