# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Errors, show_exceptions: true do
  let(:public_path) { Pathname.new(Dir.mktmpdir) }
  let(:exceptions_app) { BopsCore::PublicExceptions.new(public_path) }
  let(:show_exceptions) { ActionDispatch::ShowExceptions.new(routes.new, exceptions_app) }
  let(:app) { ActionDispatch::RequestId.new(show_exceptions, header: "X-Request-Id") }

  let(:routes) do
    Class.new do
      def call(env)
        request = ActionDispatch::Request.new(env)

        case request.path
        when "/client-error"
          raise BopsCore::Errors::ClientError
        when "/bad-request"
          raise BopsCore::Errors::BadRequestError
        when "/unauthorized"
          raise BopsCore::Errors::UnauthorizedError
        when "/forbidden"
          raise BopsCore::Errors::ForbiddenError
        when "/not-found"
          raise BopsCore::Errors::NotFoundError
        when "/not-acceptable"
          raise BopsCore::Errors::NotAcceptableError
        when "/unprocessable-content"
          raise BopsCore::Errors::UnprocessableContentError
        when "/server-error"
          raise BopsCore::Errors::ServerError
        when "/internal-server-error"
          raise BopsCore::Errors::InternalServerError
        when "/service-unavailable"
          raise BopsCore::Errors::ServiceUnavailableError
        else
          [200, {}, %w[OK]]
        end
      end
    end
  end

  let(:headers) do
    {"X-Request-Id" => "146f995c-52ef-40bb-a816-f05f05520dd4"}
  end

  around do |example|
    travel_to("2025-05-23T12:00:00Z") { example.run }
  end

  after do
    FileUtils.remove_entry(public_path)
  end

  before do
    described_class.precompile(public_path)
  end

  context "when the content-type is text/html" do
    let(:content) do
      Nokogiri::HTML5(response.body).text.gsub(/\A\s+/, "").gsub(/^\s+/, "")
    end

    describe "raising a ClientError" do
      it "renders the 400 error page" do
        get "/client-error", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(content).to match(/Sorry, we didn’t understand your request/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a BadRequestError" do
      it "renders the 400 error page" do
        get "/bad-request", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to match(/Sorry, we didn’t understand your request/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising an UnauthorizedError" do
      it "renders the 401 error page" do
        get "/unauthorized", headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to match(/Sorry, you are not allowed to access this page/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a ForbiddenError" do
      it "renders the 403 error page" do
        get "/forbidden", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to match(/Sorry, you do not have permission to access this page/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a NotFoundError" do
      it "renders the 404 error page" do
        get "/not-found", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(response.body).to match(/The page you’re looking for doesn’t exist/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a NotAcceptableError" do
      it "renders the 406 error page" do
        get "/not-acceptable", headers: headers

        expect(response).to have_http_status(:not_acceptable)
        expect(response.body).to match(/Sorry, we can’t respond to that request/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising an UnprocessableContentError" do
      it "renders the 422 error page" do
        get "/unprocessable-content", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match(/The change you wanted was rejected/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a ServerError" do
      it "renders the 500 error page" do
        get "/server-error", headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match(/Sorry, there is a problem with the service/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising an InternalServerError" do
      it "renders the 500 error page" do
        get "/internal-server-error", headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to match(/Sorry, there is a problem with the service/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end

    describe "raising a ServiceUnavailableError" do
      it "renders the 503 error page" do
        get "/service-unavailable", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to match(/Sorry, the service is unavailable/)
        expect(content).to match(/request-id: 146f995c-52ef-40bb-a816-f05f05520dd4/)
        expect(content).to match(/timestamp: 2025-05-23T12:00:00Z/)
      end
    end
  end

  context "when the content-type is application/json" do
    let(:content) do
      JSON.parse(response.body)
    end

    describe "raising a ClientError" do
      it "renders the JSON for a 400 error" do
        get "/client-error", headers: headers, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(content).to include("status" => 400)
        expect(content).to include("error" => "Bad Request")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a BadRequestError" do
      it "renders the 400 error page" do
        get "/bad-request", headers: headers, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(content).to include("status" => 400)
        expect(content).to include("error" => "Bad Request")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising an UnauthorizedError" do
      it "renders the 401 error page" do
        get "/unauthorized", headers: headers, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(content).to include("status" => 401)
        expect(content).to include("error" => "Unauthorized")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a ForbiddenError" do
      it "renders the 403 error page" do
        get "/forbidden", headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(content).to include("status" => 403)
        expect(content).to include("error" => "Forbidden")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a NotFoundError" do
      it "renders the 404 error page" do
        get "/not-found", headers: headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(content).to include("status" => 404)
        expect(content).to include("error" => "Not Found")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a NotAcceptableError" do
      it "renders the 406 error page" do
        get "/not-acceptable", headers: headers, as: :json

        expect(response).to have_http_status(:not_acceptable)
        expect(content).to include("status" => 406)
        expect(content).to include("error" => "Not Acceptable")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising an UnprocessableContentError" do
      it "renders the 422 error page" do
        get "/unprocessable-content", headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(content).to include("status" => 422)
        expect(content).to include("error" => "Unprocessable Content")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a ServerError" do
      it "renders the 500 error page" do
        get "/server-error", headers: headers, as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(content).to include("status" => 500)
        expect(content).to include("error" => "Internal Server Error")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising an InternalServerError" do
      it "renders the 500 error page" do
        get "/internal-server-error", headers: headers, as: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(content).to include("status" => 500)
        expect(content).to include("error" => "Internal Server Error")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end

    describe "raising a ServiceUnavailableError" do
      it "renders the 503 error page" do
        get "/service-unavailable", headers: headers, as: :json

        expect(response).to have_http_status(:service_unavailable)
        expect(content).to include("status" => 503)
        expect(content).to include("error" => "Service Unavailable")
        expect(content).to include("request-id" => "146f995c-52ef-40bb-a816-f05f05520dd4")
        expect(content).to include("timestamp" => "2025-05-23T12:00:00Z")
      end
    end
  end
end
