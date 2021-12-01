# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdditionalDocumentValidationRequest, type: :model do
  include ActionDispatch::TestProcess::FixtureFile

  let(:additional_document_validation_request) { create(:additional_document_validation_request, :open) }
  let(:api_user) { create(:api_user) }
  let(:files) do
    [
      fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png"),
      fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-roofplan.pdf"), "proposed-roofplan/pdf")
    ]
  end

  it_behaves_like "ValidationRequest", described_class, "additional_document_validation_request"

  describe "instance methods" do
    describe "#upload_files!" do
      before { Current.api_user = api_user }

      describe "when successful" do
        it "uploads the files, saves them as documents and creates an audit record" do
          expect { additional_document_validation_request.upload_files!(files) }
            .to change(additional_document_validation_request, :state).from("open").to("closed")

          additional_document_validation_request.reload

          expect(Audit.last).to have_attributes(
            planning_application_id: additional_document_validation_request.planning_application.id,
            activity_type: "additional_document_validation_request_received",
            activity_information: "1",
            audit_comment: "proposed-floorplan.png, proposed-roofplan.pdf",
            api_user_id: api_user.id
          )

          documents = additional_document_validation_request.documents
          expect(documents.length).to eq(2)
          expect(documents.map(&:name).map(&:to_s)).to include("proposed-floorplan.png", "proposed-roofplan.pdf")
          expect(documents.pluck(:additional_document_validation_request_id)).to eq(
            [
              additional_document_validation_request.id, additional_document_validation_request.id
            ]
          )
        end
      end

      describe "when there is an error" do
        it "when request is in closed state it raises AdditionalDocumentValidationRequest::UploadFilesError" do
          additional_document_validation_request.update(state: "closed")

          expect { additional_document_validation_request.upload_files!(files) }
            .to raise_error(AdditionalDocumentValidationRequest::UploadFilesError,
                            "Event 'close' cannot transition from 'closed'.")
            .and change(Audit, :count).by(0)

          additional_document_validation_request.reload
          expect(additional_document_validation_request).to be_closed
          expect(additional_document_validation_request.documents).to eq([])
        end
      end
    end
  end
end
