# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Routing, show_exceptions: true do
  with_routing do |set|
    set.draw do
      extend BopsCore::Routing

      bops_domain do
        public_subdomain do
          get "/public", to: proc { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
        end

        local_authority_subdomain do
          get "/la-bops", to: proc { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
        end

        config_subdomain do
          get "/config", to: proc { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
        end

        devise_subdomain do
          get "/login", to: proc { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
        end
      end

      applicants_domain do
        local_authority_subdomain do
          get "/la-applicants", to: proc { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
        end
      end
    end
  end

  context "when in development" do
    let!(:local_authority) { create(:local_authority, :default) }

    before do
      allow(Rails.application.config).to receive(:domain).and_return("bops.localhost:3000")
      allow(Rails.application.config).to receive(:applicants_domain).and_return("bops-applicants.localhost:3000")
    end

    context "and making a request on the bops domain" do
      before do
        host! "planx.bops.localhost:3000"
      end

      it "routes correctly" do
        get "/public"
        expect(response).to have_http_status(:not_found)

        get "/la-bops"
        expect(response).to have_http_status(:ok)

        get "/login"
        expect(response).to have_http_status(:ok)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:not_found)
      end

      context "and making a request on the config subdomain" do
        before do
          host! "config.bops.localhost:3000"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:not_found)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:ok)

          get "/config"
          expect(response).to have_http_status(:ok)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on the public subdomain" do
        before do
          host! "www.bops.localhost:3000"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on no subdomain" do
        before do
          host! "bops.localhost:3000"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "and making a request on the applicants domain" do
      before do
        host! "planx.bops-applicants.localhost:3000"
      end

      it "routes correctly" do
        get "/public"
        expect(response).to have_http_status(:not_found)

        get "/la-bops"
        expect(response).to have_http_status(:not_found)

        get "/login"
        expect(response).to have_http_status(:not_found)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when on staging" do
    let!(:local_authority) { create(:local_authority, :default) }

    before do
      allow(Rails.application.config).to receive(:domain).and_return("bops-staging.services")
      allow(Rails.application.config).to receive(:applicants_domain).and_return("bops-applicants-staging.services")
    end

    context "and making a request on the bops domain" do
      before do
        host! "planx.bops-staging.services"
      end

      it "routes correctly" do
        get "/la-bops"
        expect(response).to have_http_status(:ok)

        get "/login"
        expect(response).to have_http_status(:ok)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:not_found)
      end

      context "and making a request on the config subdomain" do
        before do
          host! "config.bops-staging.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:not_found)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:ok)

          get "/config"
          expect(response).to have_http_status(:ok)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on the public subdomain" do
        before do
          host! "www.bops-staging.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on no subdomain" do
        before do
          host! "bops-staging.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "and making a request on the applicants domain" do
      before do
        host! "planx.bops-applicants-staging.services"
      end

      it "routes correctly" do
        get "/public"
        expect(response).to have_http_status(:not_found)

        get "/la-bops"
        expect(response).to have_http_status(:not_found)

        get "/login"
        expect(response).to have_http_status(:not_found)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when on production" do
    let!(:local_authority) { create(:local_authority, :default) }

    before do
      allow(Rails.application.config).to receive(:domain).and_return("bops.services")
      allow(Rails.application.config).to receive(:applicants_domain).and_return("applicants.bops.services")
    end

    context "and making a request on the bops domain" do
      before do
        host! "planx.bops.services"
      end

      it "routes correctly" do
        get "/public"
        expect(response).to have_http_status(:not_found)

        get "/la-bops"
        expect(response).to have_http_status(:ok)

        get "/login"
        expect(response).to have_http_status(:ok)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:not_found)
      end

      context "and making a request on the config subdomain" do
        before do
          host! "config.bops.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:not_found)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:ok)

          get "/config"
          expect(response).to have_http_status(:ok)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on the public subdomain" do
        before do
          host! "www.bops.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end

      context "and making a request on no subdomain" do
        before do
          host! "bops.services"
        end

        it "routes correctly" do
          get "/public"
          expect(response).to have_http_status(:ok)

          get "/la-bops"
          expect(response).to have_http_status(:not_found)

          get "/login"
          expect(response).to have_http_status(:not_found)

          get "/config"
          expect(response).to have_http_status(:not_found)

          get "/la-applicants"
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "and making a request on the applicants domain" do
      before do
        host! "planx.applicants.bops.services"
      end

      it "routes correctly" do
        get "/public"
        expect(response).to have_http_status(:not_found)

        get "/la-bops"
        expect(response).to have_http_status(:not_found)

        get "/login"
        expect(response).to have_http_status(:not_found)

        get "/config"
        expect(response).to have_http_status(:not_found)

        get "/la-applicants"
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
