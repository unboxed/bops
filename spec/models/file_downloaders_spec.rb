# frozen_string_literal: true

require "rails_helper"

RSpec.describe FileDownloaders, type: :model do
  subject { described_class.new(attributes) }

  let(:url) { "https://example.com/path/to/file.pdf" }
  let(:stubbed_request) { stub_request(:get, url) }

  let(:response) do
    {status: 200, headers: {"Content-Type" => "application/pdf"}, body: "%PDF-1.3\n"}
  end

  before do
    stubbed_request.to_return(response)
    subject.get(url)
  end

  describe FileDownloaders::BasicAuthentication do
    let(:attributes) do
      {username: "username", password: "password"}
    end

    let(:headers) do
      {"Authorization" => "Basic dXNlcm5hbWU6cGFzc3dvcmQ="}
    end

    it "authenticates the request using basic authentication" do
      expect(WebMock).to have_requested(:get, url).with(headers: headers)
    end
  end

  describe FileDownloaders::BearerAuthentication do
    let(:attributes) do
      {token: "76Vncyn5avSqahcD5h3te3yn"}
    end

    let(:headers) do
      {"Authorization" => "Bearer 76Vncyn5avSqahcD5h3te3yn"}
    end

    it "authenticates the request using a bearer token" do
      expect(WebMock).to have_requested(:get, url).with(headers: headers)
    end
  end

  describe FileDownloaders::HeaderAuthentication do
    let(:attributes) do
      {key: "Api-Key", value: "SKhExJz2Akhi9yixppWFSRxS"}
    end

    let(:headers) do
      {"Api-Key" => "SKhExJz2Akhi9yixppWFSRxS"}
    end

    it "authenticates the request using a header" do
      expect(WebMock).to have_requested(:get, url).with(headers: headers)
    end
  end
end
