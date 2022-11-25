# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetailsReview do
  describe "#save" do
    let(:planning_application) { create(:planning_application) }
    let(:user) { create(:user) }

    let(:assessment_details_review) do
      described_class.new(
        planning_application: planning_application,
        **params
      )
    end

    before do
      create(
        :recommendation,
        :assessment_complete,
        planning_application: planning_application
      )

      create(:consultee, planning_application: planning_application)
      Current.user = user
    end

    context "when assessment detail records exist" do
      let!(:summary_of_work) do
        create(
          :assessment_detail,
          :summary_of_work,
          planning_application: planning_application,
          entry: "summary of work",
          status: :assessment_complete
        )
      end

      let!(:additional_evidence) do
        create(
          :assessment_detail,
          :additional_evidence,
          planning_application: planning_application,
          entry: "additional evidence",
          status: :assessment_complete
        )
      end

      let!(:consultation_summary) do
        create(
          :assessment_detail,
          :consultation_summary,
          planning_application: planning_application,
          entry: "consultation summary",
          status: :assessment_complete
        )
      end

      let!(:site_description) do
        create(
          :assessment_detail,
          :site_description,
          planning_application: planning_application,
          entry: "site description",
          status: :assessment_complete
        )
      end

      before { assessment_details_review.save }

      context "when status is 'in progress'" do
        context "when review status 'accepted'" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :accepted,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "updates summary of work" do
            expect(summary_of_work.reload).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "updates additional evidence" do
            expect(additional_evidence.reload).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "updates site description" do
            expect(site_description.reload).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "updates consultation summmary" do
            expect(consultation_summary.reload).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end
        end

        context "when review status 'rejected' and comment text is present" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :rejected,
              site_description_review_status: :rejected,
              additional_evidence_review_status: :rejected,
              consultation_summary_review_status: :rejected,
              summary_of_work_comment_text: "summary of work comment",
              site_description_comment_text: "site description comment",
              additional_evidence_comment_text: "additional evidence comment",
              consultation_summary_comment_text: "consultation summary comment"
            }
          end

          it "updates summary of work" do
            expect(summary_of_work.reload).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "updates additional evidence" do
            expect(additional_evidence.reload).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "updates site description" do
            expect(site_description.reload).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "updates consultation summary" do
            expect(consultation_summary.reload).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "creates comment for summary of work" do
            expect(summary_of_work.reload.comment).to have_attributes(
              text: "summary of work comment"
            )
          end

          it "creates comment for additional evidence" do
            expect(additional_evidence.reload.comment).to have_attributes(
              text: "additional evidence comment"
            )
          end

          it "creates comment for site description" do
            expect(site_description.reload.comment).to have_attributes(
              text: "site description comment"
            )
          end

          it "creates comment for consultation summary" do
            expect(consultation_summary.reload.comment).to have_attributes(
              text: "consultation summary comment"
            )
          end
        end

        context "when review status is 'rejected' and comment text is blank" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :rejected,
              site_description_review_status: :rejected,
              additional_evidence_review_status: :rejected,
              consultation_summary_review_status: :rejected,
              summary_of_work_comment_text: "",
              site_description_comment_text: "",
              additional_evidence_comment_text: "",
              consultation_summary_comment_text: ""
            }
          end

          it "sets summary of work error message" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets site description error message" do
            expect(
              assessment_details_review.errors.messages[:site_description_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets additional evidence error message" do
            expect(
              assessment_details_review.errors.messages[:additional_evidence_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets consultation summary error message" do
            expect(
              assessment_details_review.errors.messages[:consultation_summary_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end

        context "when review status 'edited and accepted' and entry is present" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :edited_and_accepted,
              site_description_review_status: :edited_and_accepted,
              additional_evidence_review_status: :edited_and_accepted,
              consultation_summary_review_status: :edited_and_accepted,
              summary_of_work_entry: "edited summary of work",
              site_description_entry: "edited site description",
              additional_evidence_entry: "edited additional evidence",
              consultation_summary_entry: "edited consultation summary"
            }
          end

          it "updates summary of work" do
            expect(summary_of_work.reload).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited summary of work"
            )
          end

          it "updates site description" do
            expect(site_description.reload).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited site description"
            )
          end

          it "updates additional evidence" do
            expect(additional_evidence.reload).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited additional evidence"
            )
          end

          it "updates consultation summary" do
            expect(consultation_summary.reload).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited consultation summary"
            )
          end
        end

        context "when review status 'edited and accepted' and entry is blank" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :edited_and_accepted,
              site_description_review_status: :edited_and_accepted,
              additional_evidence_review_status: :edited_and_accepted,
              consultation_summary_review_status: :edited_and_accepted,
              summary_of_work_entry: "",
              site_description_entry: "",
              additional_evidence_entry: "",
              consultation_summary_entry: ""
            }
          end

          it "sets summary of work error message" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets site description error message" do
            expect(
              assessment_details_review.errors.messages[:site_description_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets additional evidence error message" do
            expect(
              assessment_details_review.errors.messages[:additional_evidence_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets consultation summary error message" do
            expect(
              assessment_details_review.errors.messages[:consultation_summary_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end

        context "when review status 'edited and accepted' and entry not edited" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :edited_and_accepted,
              site_description_review_status: :edited_and_accepted,
              additional_evidence_review_status: :edited_and_accepted,
              consultation_summary_review_status: :edited_and_accepted,
              summary_of_work_entry: "summary of work",
              site_description_entry: "site description",
              additional_evidence_entry: "additional evidence",
              consultation_summary_entry: "consultation summary"
            }
          end

          it "sets summary of work error message" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_entry]
            ).to contain_exactly(
              "must be edited"
            )
          end

          it "sets site description error message" do
            expect(
              assessment_details_review.errors.messages[:site_description_entry]
            ).to contain_exactly(
              "must be edited"
            )
          end

          it "sets additional evidence error message" do
            expect(
              assessment_details_review.errors.messages[:additional_evidence_entry]
            ).to contain_exactly(
              "must be edited"
            )
          end

          it "sets consultation summary error message" do
            expect(
              assessment_details_review.errors.messages[:consultation_summary_entry]
            ).to contain_exactly(
              "must be edited"
            )
          end
        end

        context "when review status is nil" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: nil,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "does not set an error" do
            expect(assessment_details_review.errors.messages).to be_empty
          end
        end
      end

      context "when status is 'complete'" do
        context "when all review statuses are present" do
          let(:params) do
            {
              status: :complete,
              summary_of_work_review_status: :accepted,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "updates summary of work" do
            expect(summary_of_work.reload).to have_attributes(
              review_status: "accepted",
              status: "review_complete"
            )
          end
        end

        context "when any review status is nil" do
          let(:params) do
            {
              status: :complete,
              summary_of_work_review_status: nil,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "sets an error" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_review_status]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end
      end
    end

    context "when assessment detail records do not exist" do
      before { assessment_details_review.save }

      context "when status is 'in progress'" do
        context "when review status 'accepted'" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :accepted,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "creates summary of work" do
            expect(
              planning_application.reload.summary_of_work
            ).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "creates additional evidence" do
            expect(
              planning_application.reload.additional_evidence
            ).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "creates site description" do
            expect(
              planning_application.reload.site_description
            ).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end

          it "creates consultation summmary" do
            expect(
              planning_application.reload.consultation_summary
            ).to have_attributes(
              review_status: "accepted",
              status: "review_in_progress"
            )
          end
        end

        context "when review status is 'rejected' and comment text is present" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :rejected,
              site_description_review_status: :rejected,
              additional_evidence_review_status: :rejected,
              consultation_summary_review_status: :rejected,
              summary_of_work_comment_text: "summary of work comment",
              site_description_comment_text: "site description comment",
              additional_evidence_comment_text: "additional evidence comment",
              consultation_summary_comment_text: "consultation summary comment"
            }
          end

          it "creates summary of work" do
            expect(
              planning_application.reload.summary_of_work
            ).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "creates additional evidence" do
            expect(
              planning_application.reload.additional_evidence
            ).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "creates site description" do
            expect(
              planning_application.reload.site_description
            ).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "creates consultation summary" do
            expect(
              planning_application.reload.consultation_summary
            ).to have_attributes(
              review_status: "rejected",
              status: "review_in_progress"
            )
          end

          it "creates comment for summary of work" do
            expect(
              planning_application.reload.summary_of_work.comment
            ).to have_attributes(
              text: "summary of work comment"
            )
          end

          it "creates comment for additional evidence" do
            expect(
              planning_application.reload.additional_evidence.comment
            ).to have_attributes(
              text: "additional evidence comment"
            )
          end

          it "creates comment for site description" do
            expect(
              planning_application.reload.site_description.comment
            ).to have_attributes(
              text: "site description comment"
            )
          end

          it "creates comment for consultation summary" do
            expect(
              planning_application.reload.consultation_summary.comment
            ).to have_attributes(
              text: "consultation summary comment"
            )
          end
        end

        context "when review status is 'rejected' and comment text is blank" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :rejected,
              site_description_review_status: :rejected,
              additional_evidence_review_status: :rejected,
              consultation_summary_review_status: :rejected,
              summary_of_work_comment_text: "",
              site_description_comment_text: "",
              additional_evidence_comment_text: "",
              consultation_summary_comment_text: ""
            }
          end

          it "sets summary of work error message" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets site description error message" do
            expect(
              assessment_details_review.errors.messages[:site_description_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets additional evidence error message" do
            expect(
              assessment_details_review.errors.messages[:additional_evidence_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets consultation summary error message" do
            expect(
              assessment_details_review.errors.messages[:consultation_summary_comment_text]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end

        context "when review status 'edited and accepted' and entry is present" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :edited_and_accepted,
              site_description_review_status: :edited_and_accepted,
              additional_evidence_review_status: :edited_and_accepted,
              consultation_summary_review_status: :edited_and_accepted,
              summary_of_work_entry: "edited summary of work",
              site_description_entry: "edited site description",
              additional_evidence_entry: "edited additional evidence",
              consultation_summary_entry: "edited consultation summary"
            }
          end

          it "creates summary of work" do
            expect(
              planning_application.reload.summary_of_work
            ).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited summary of work"
            )
          end

          it "creates site description" do
            expect(
              planning_application.reload.site_description
            ).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited site description"
            )
          end

          it "creates additional evidence" do
            expect(
              planning_application.reload.additional_evidence
            ).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited additional evidence"
            )
          end

          it "creates consultation summary" do
            expect(
              planning_application.reload.consultation_summary
            ).to have_attributes(
              review_status: "edited_and_accepted",
              status: "review_in_progress",
              entry: "edited consultation summary"
            )
          end
        end

        context "when review status is 'edited and accepted' and entry is blank" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: :edited_and_accepted,
              site_description_review_status: :edited_and_accepted,
              additional_evidence_review_status: :edited_and_accepted,
              consultation_summary_review_status: :edited_and_accepted,
              summary_of_work_entry: "",
              site_description_entry: "",
              additional_evidence_entry: "",
              consultation_summary_entry: ""
            }
          end

          it "sets summary of work error message" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets site description error message" do
            expect(
              assessment_details_review.errors.messages[:site_description_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets additional evidence error message" do
            expect(
              assessment_details_review.errors.messages[:additional_evidence_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end

          it "sets consultation summary error message" do
            expect(
              assessment_details_review.errors.messages[:consultation_summary_entry]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end

        context "when any review status is nil" do
          let(:params) do
            {
              status: :in_progress,
              summary_of_work_review_status: nil,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "does not set an error" do
            expect(assessment_details_review.errors.messages).to be_empty
          end
        end
      end

      context "when status is 'complete'" do
        context "when all review statuses are present" do
          let(:params) do
            {
              status: :complete,
              summary_of_work_review_status: :accepted,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "creates summary of work" do
            expect(
              planning_application.reload.summary_of_work
            ).to have_attributes(
              review_status: "accepted",
              status: "review_complete"
            )
          end
        end

        context "when any review status is nil" do
          let(:params) do
            {
              status: :complete,
              summary_of_work_review_status: nil,
              additional_evidence_review_status: :accepted,
              site_description_review_status: :accepted,
              consultation_summary_review_status: :accepted
            }
          end

          it "sets an error" do
            expect(
              assessment_details_review.errors.messages[:summary_of_work_review_status]
            ).to contain_exactly(
              "can't be blank"
            )
          end
        end
      end
    end

    context "when recommendation has been accepted" do
      let(:params) do
        {
          status: :complete,
          summary_of_work_review_status: :accepted,
          additional_evidence_review_status: :accepted,
          site_description_review_status: :accepted,
          consultation_summary_review_status: :rejected,
          consultation_summary_comment_text: "consultation summary comment"
        }
      end

      before do
        create(
          :recommendation,
          :review_complete,
          planning_application: planning_application,
          challenged: false
        )

        assessment_details_review.save
      end

      it "sets error" do
        expect(assessment_details_review.errors[:base]).to contain_exactly(
          "You agreed with the assessor recommendation, to request any change you must change your decision on the Sign-off recommendation screen"
        )
      end
    end
  end
end
