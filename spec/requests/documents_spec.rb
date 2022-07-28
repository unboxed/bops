# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents", type: :request, show_exceptions: true do
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:other_local_authority) { create(:local_authority) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  let!(:planning_application) { create(:planning_application, local_authority: other_local_authority) }

  # TODO: add the rest of the actions on documents controller
  it "returns 404 when trying to index documents for a planning application on another local authority" do
    sign_in assessor
    expect do
      get planning_application_documents_path(planning_application)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "returns 415 if the content type is invalid" do
    sign_in assessor

    checksum = OpenSSL::Digest.base64digest("MD5", "Hello")
    metadata = {
      foo: "bar",
      my_key_1: "my_value_1",
      my_key_2: "my_value_2",
      platform: "my_platform",
      library_ID: "12345",
      custom: {
        my_key_3: "my_value_3"
      }
    }

    expect do
      post rails_direct_uploads_url, params: { blob: {
        filename: "hello.txt", byte_size: 6, checksum: checksum, content_type: "text/plain", metadata: metadata
      } }
    end.to raise_error(ActiveStorage::NotPermittedContentType)
  end
end
