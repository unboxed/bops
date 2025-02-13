# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Middleware::User do
  let(:local_authority) { create(:local_authority, subdomain: "royston") }
  let(:response) { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
  let(:app) { double(call: response) }

  let(:global_scope) { ::User.global.kept.to_sql }
  let(:local_authority_scope) { local_authority.users.kept.to_sql }
  let(:null_scope) { ::User.none.to_sql }

  subject { described_class.new(app, global_subdomains: %w[config]) }

  describe "#call" do
    context "when the request is on a global subdomain" do
      let(:env) do
        {
          "HTTP_HOST" => "config.bops.services",
          "bops.local_authority" => nil
        }
      end

      it "sets the user scope in the request hash to the global scope" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.user_scope")
        }.from(false).to(true)

        expect(env["bops.user_scope"].to_sql).to eq(global_scope)
      end
    end

    context "when the request is on a local authority subdomain" do
      let(:env) do
        {
          "HTTP_HOST" => "#{local_authority.subdomain}.bops.services",
          "bops.local_authority" => local_authority
        }
      end

      it "sets the user scope in the request hash to the local authority scope" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.user_scope")
        }.from(false).to(true)

        expect(env["bops.user_scope"].to_sql).to eq(local_authority_scope)
      end
    end

    context "when the request is on a unknown subdomain" do
      let(:env) do
        {
          "HTTP_HOST" => "other.bops.services",
          "bops.local_authority" => nil
        }
      end

      it "sets the user scope in the request hash to the null scope" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.user_scope")
        }.from(false).to(true)

        expect(env["bops.user_scope"].to_sql).to eq(null_scope)
      end
    end
  end
end
