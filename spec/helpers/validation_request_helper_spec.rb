# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequestHelper do
  let(:planning_application) { create(:planning_application, :invalidated) }
  let!(:request) { create(:other_change_validation_request, planning_application:) }
  let(:document) { create(:document, planning_application:) }

  describe "#show_validation_request_link" do
    let(:request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:
      )
    end

    before do
      helper.instance_variable_set(:@virtual_path, "validation_requests.table")
    end

    context "when planning application has not been validated" do
      it "returns link to request page" do
        expect(
          helper.show_validation_request_link(planning_application, request)
        ).to eq(
          "<a href=\"/planning_applications/#{planning_application.id}/validation/validation_requests/#{request.id}\">View and update</a>"
        )
      end

      context "when request is for additional document" do
        let(:request) do
          create(
            :additional_document_validation_request,
            planning_application:
          )
        end

        it "returns link to validation documents page" do
          expect(
            helper.show_validation_request_link(planning_application, request)
          ).to eq(
            "<a href=\"/planning_applications/#{planning_application.id}/validation/documents/edit\">View and update</a>"
          )
        end
      end
    end

    context "when planning application has been validated" do
      let(:planning_application) do
        create(:planning_application, :in_assessment)
      end

      it "returns link to request page" do
        expect(
          helper.show_validation_request_link(planning_application, request)
        ).to eq(
          "<a href=\"/planning_applications/#{planning_application.id}/validation/validation_requests/#{request.id}\">View</a>"
        )
      end

      context "when request is for additional document" do
        let(:request) do
          create(
            :additional_document_validation_request,
            planning_application:
          )
        end

        it "returns link to documents page" do
          expect(
            helper.show_validation_request_link(planning_application, request)
          ).to eq(
            "<a href=\"/planning_applications/#{planning_application.id}/documents\">View</a>"
          )
        end
      end
    end
  end
end
