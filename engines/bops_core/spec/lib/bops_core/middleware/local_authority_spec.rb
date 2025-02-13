# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Middleware::LocalAuthority do
  let(:local_authority) { create(:local_authority, subdomain: "royston") }
  let(:response) { [200, {"Content-Type" => "text/plain"}, %w[OK]] }
  let(:app) { double(call: response) }

  subject { described_class.new(app) }

  describe "#call" do
    context "when on a global subdomain" do
      let(:env) { {"HTTP_HOST" => "config.bops.services"} }

      it "sets the local authority in the request hash to nil" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.local_authority")
        }.from(false).to(true)

        expect(env["bops.local_authority"]).to be_nil
      end
    end

    context "when on a local authority subdomain" do
      let(:env) { {"HTTP_HOST" => "#{local_authority.subdomain}.bops.services"} }

      it "sets the local authority in the request hash" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.local_authority")
        }.from(false).to(true)

        expect(env["bops.local_authority"]).to eq(local_authority)
      end
    end

    context "when on an unknown subdomain" do
      let(:env) { {"HTTP_HOST" => "other.bops.services"} }

      it "sets the local authority in the request hash to nil" do
        expect {
          expect(subject.call(env)).to eq(response)
        }.to change {
          env.has_key?("bops.local_authority")
        }.from(false).to(true)

        expect(env["bops.local_authority"]).to be_nil
      end
    end
  end
end
