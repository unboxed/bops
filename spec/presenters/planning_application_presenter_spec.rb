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

  describe "#grouped_proposal_details" do
    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{ value: "Answer 1" }],
          metadata: { portal_name: "Group B" }
        },
        {
          question: "Question 2",
          responses: [{ value: "Answer 2" }],
          metadata: { portal_name: "Group A" }
        },
        {
          question: "Question 3",
          responses: [{ value: "Answer 3" }],
          metadata: { portal_name: "Group B" }
        },
        {
          question: "Question 4",
          responses: [{ value: "Answer 4" }]
        }
      ].to_json
    end

    let(:planning_application) do
      create(:planning_application, proposal_details: proposal_details)
    end

    it "returns proposal details grouped by by portal name" do
      expect(presenter.grouped_proposal_details).to eq(
        [
          [
            "Group B",
            [
              OpenStruct.new(
                {
                  question: "Question 1",
                  responses: [OpenStruct.new({ value: "Answer 1" })],
                  metadata: OpenStruct.new({ portal_name: "Group B" })
                }
              ),
              OpenStruct.new(
                {
                  question: "Question 3",
                  responses: [OpenStruct.new({ value: "Answer 3" })],
                  metadata: OpenStruct.new({ portal_name: "Group B" })
                }
              )
            ]
          ],
          [
            "Group A",
            [
              OpenStruct.new(
                {
                  question: "Question 2",
                  responses: [OpenStruct.new({ value: "Answer 2" })],
                  metadata: OpenStruct.new({ portal_name: "Group A" })
                }
              )
            ]
          ],
          [
            nil,
            [
              OpenStruct.new(
                {
                  question: "Question 4",
                  responses: [OpenStruct.new({ value: "Answer 4" })]
                }
              )
            ]
          ]
        ]
      )
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

  describe "#grouped_proposal_details_with_start_numbers" do
    let(:proposal_details) do
      [
        {
          question: "Question 1",
          responses: [{ value: "Answer 1" }],
          metadata: { portal_name: "Group A" }
        },
        {
          question: "Question 2",
          responses: [{ value: "Answer 2" }],
          metadata: { portal_name: "Group A" }
        },
        {
          question: "Question 3",
          responses: [{ value: "Answer 3" }],
          metadata: { portal_name: "Group B" }
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

    it "returns proposal detail groups with start numbers" do
      expect(presenter.grouped_proposal_details_with_start_numbers).to eq(
        [
          [
            "Group A",
            [
              OpenStruct.new(
                {
                  question: "Question 1",
                  responses: [OpenStruct.new({ value: "Answer 1" })],
                  metadata: OpenStruct.new({ portal_name: "Group A" })
                }
              ),
              OpenStruct.new(
                {
                  question: "Question 2",
                  responses: [OpenStruct.new({ value: "Answer 2" })],
                  metadata: OpenStruct.new({ portal_name: "Group A" })
                }
              )
            ],
            1
          ],
          [
            "Group B",
            [
              OpenStruct.new(
                {
                  question: "Question 3",
                  responses: [OpenStruct.new({ value: "Answer 3" })],
                  metadata: OpenStruct.new({ portal_name: "Group B" })
                }
              )
            ],
            3
          ],
          [
            "Group C",
            [
              OpenStruct.new(
                {
                  question: "Question 4",
                  responses: [OpenStruct.new({ value: "Answer 4" })],
                  metadata: OpenStruct.new({ portal_name: "Group C" })
                }
              )
            ],
            4
          ]
        ]
      )
    end
  end
end
