# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::ApplicationController, type: :controller do
  controller(ActionController::Base) do
    include BopsCore::ApplicationController

    def index
      render plain: <<~TEXT
        Local Authority: #{Current.local_authority.subdomain.inspect}
        User ID: #{Current.user&.id.inspect}
        API User ID: #{Current.api_user&.id.inspect}
      TEXT
    end
  end

  let(:local_authority) { create(:local_authority) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:api_user) { create(:api_user, local_authority:) }

  before do
    request.env["HTTP_HOST"] = "#{local_authority.subdomain}.bops.services"
    request.env["bops.local_authority"] = local_authority
    request.env["bops.user_scope"] = local_authority.users.kept
  end

  describe "#set_current" do
    before do
    end

    it "sets the current local authority" do
      get :index

      expect(response.body).to match(/Local Authority: "#{local_authority.subdomain}"/)
    end

    context "for an API request" do
      before do
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{api_user.token}"
      end

      it "sets the current api user" do
        get :index

        expect(response.body).to match(/API User ID: #{api_user.id}/)
      end
    end

    context "for a navigable request" do
      before do
        sign_in(user)
      end

      it "sets the current user" do
        get :index

        expect(response.body).to match(/User ID: #{user.id}/)
      end
    end
  end

  describe "#set_appsignal_tags" do
    before do
      allow(Appsignal).to receive(:add_tags)
    end

    context "for an API request" do
      before do
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{api_user.token}"
      end

      it "tags a request context with relevant data" do
        get :index

        expect(Appsignal).to have_received(:add_tags).with(
          local_authority: local_authority.subdomain, api_user_id: api_user.id
        )
      end
    end

    context "for a navigable request" do
      before do
        sign_in(user)
      end

      it "tags a request context with relevant data" do
        get :index

        expect(Appsignal).to have_received(:add_tags).with(
          local_authority: local_authority.subdomain, user_id: user.id
        )
      end
    end
  end
end
