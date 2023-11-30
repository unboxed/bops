# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdditionalDocumentValidationRequest do
  include ActionDispatch::TestProcess::FixtureFile

  include_examples "ValidationRequest", described_class, "additional_document_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:additional_document_validation_request) }
  end

  describe "validations" do
    subject(:additional_document_validation_request) { described_class.new }

    describe "#document_request_type" do
      it "validates presence" do
        expect do
          additional_document_validation_request.valid?
        end.to change {
          additional_document_validation_request.errors[:document_request_type]
        }.to ["Fill in the document request type."]
      end
    end

    describe "#document_request_reason" do
      it "validates presence" do
        expect do
          additional_document_validation_request.valid?
        end.to change {
          additional_document_validation_request.errors[:reason]
        }.to ["Provide a reason for changes"]
      end
    end
  end

  describe "instance methods" do
    let(:additional_document_validation_request) { create(:additional_document_validation_request, :open) }
    let(:api_user) { create(:api_user) }
    let(:files) do
      [
        fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png"),
        fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-roofplan.pdf"), "proposed-roofplan/pdf")
      ]
    end

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

          documents = additional_document_validation_request.additional_documents
          expect(documents.length).to eq(2)
          expect(documents.map(&:name).map(&:to_s)).to include("proposed-floorplan.png", "proposed-roofplan.pdf")
          expect(documents.pluck(:owner_id)).to eq(
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
            .and not_change(Audit, :count)

          additional_document_validation_request.reload
          expect(additional_document_validation_request).to be_closed
          expect(additional_document_validation_request.additional_documents).to eq([])
        end
      end
    end
  end

  describe "callbacks" do
    describe "::before_destroy #reset_missing_documents" do
      let!(:planning_application) do
        create(:planning_application, :not_started, documents_missing: true)
      end
      let!(:additional_document_validation_request) do
        create(:additional_document_validation_request, :pending, planning_application:)
      end

      before do
        additional_document_validation_request.destroy!
      end

      context "when there are more than one open or pending additional document validation requests" do
        before do
          create(:additional_document_validation_request, :pending, planning_application:)
        end

        it "does not update documents_missing on the planning application" do
          expect(planning_application.reload.documents_missing).to be(true)
        end
      end

      context "when there is only one open or pending additional document validation requests" do
        it "does update and resets the documents_missing on the planning application to nil" do
          expect(planning_application.reload.documents_missing).to be_nil
        end
      end
    end

    describe "::after_create #set_missing_documents" do
      let!(:planning_application) do
        create(:planning_application, :not_started)
      end

      let(:additional_document_validation_request) do
        create(:additional_document_validation_request, :pending, planning_application:)
      end

      it "updates documents_missing on planning application to true" do
        expect do
          additional_document_validation_request
        end.to change(planning_application, :documents_missing).from(nil).to(true)
      end
    end

    describe "#can_cancel?" do
      context "when request is open" do
        let(:request) do
          create(
            :additional_document_validation_request,
            :open,
            planning_application:
          )
        end

        context "when planning application is invalidated" do
          let(:planning_application) do
            create(:planning_application, :invalidated)
          end

          it "returns true" do
            expect(request.can_cancel?).to be(true)
          end
        end

        context "when planning application is not invalidated" do
          let(:planning_application) do
            create(:planning_application, :not_started)
          end

          it "returns false" do
            expect(request.can_cancel?).to be(false)
          end
        end

        context "when request is post validation" do
          let(:planning_application) do
            create(:planning_application, :in_assessment)
          end

          it "returns true" do
            expect(request.can_cancel?).to be(true)
          end
        end
      end

      context "when request is pending" do
        let(:request) do
          create(
            :additional_document_validation_request,
            :pending,
            planning_application:
          )
        end

        context "when planning application is invalidated" do
          let(:planning_application) do
            create(:planning_application, :invalidated)
          end

          it "returns true" do
            expect(request.can_cancel?).to be(true)
          end
        end

        context "when planning application is not invalidated" do
          let(:planning_application) do
            create(:planning_application, :not_started)
          end

          it "returns false" do
            expect(request.can_cancel?).to be(false)
          end
        end

        context "when request is post validation" do
          let(:planning_application) do
            create(:planning_application, :in_assessment)
          end

          it "returns true" do
            expect(request.can_cancel?).to be(true)
          end
        end
      end

      context "when request is not open or pending" do
        let(:request) do
          create(
            :additional_document_validation_request,
            :closed,
            planning_application:
          )
        end

        context "when planning application is invalidated" do
          let(:planning_application) do
            create(:planning_application, :invalidated)
          end

          it "returns false" do
            expect(request.can_cancel?).to be(false)
          end
        end

        context "when request is post validation" do
          let(:planning_application) do
            create(:planning_application, :in_assessment)
          end

          it "returns false" do
            expect(request.can_cancel?).to be(false)
          end
        end
      end
    end
  end
end
