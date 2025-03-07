# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe BopsConfig::ApplicationTypesController, type: :controller do
  let(:user) { create(:user, :global_administrator, local_authority: nil) }

  before do
    sign_in(user)
  end

  routes { BopsConfig::Engine.routes }

  describe "#create" do
    context "with invalid params" do
      it "doesn't send an audit event" do
        expect {
          post :create, params: {application_type: {code: "", suffix: ""}}
        }.not_to have_audit("created.application_type")
      end
    end

    context "with valid params" do
      it "sends an audit event" do
        expect {
          post :create, params: {application_type: {code: "advertConsent", suffix: "ADVT"}}
        }.to have_audit("created.application_type").with_payload(a_hash_including(
          engine: "bops_config",
          params: {action: "create", controller: "bops_config/application_types"},
          user: {"id" => user.id, "name" => user.name, "role" => user.role},
          application_type: {"code" => "advertConsent"},
          changes: a_hash_including(
            "code" => [nil, "advertConsent"],
            "suffix" => [nil, "ADVT"]
          ),
          automated: false
        ))
      end
    end
  end

  describe "#update" do
    let!(:application_type) { create(:application_type_config, :inactive, code: "advertConsent", suffix: "ADVR") }

    context "with invalid params" do
      it "doesn't send an audit event" do
        expect {
          post :update, params: {id: application_type.id, application_type: {code: "", suffix: ""}}
        }.not_to have_audit("updated.application_type")
      end
    end

    context "with valid params" do
      it "sends an audit event" do
        expect {
          post :update, params: {id: application_type.id, application_type: {code: "advertConsent", suffix: "ADVT"}}
        }.to have_audit("updated.application_type").with_payload(a_hash_including(
          engine: "bops_config",
          params: {action: "update", controller: "bops_config/application_types", id: application_type.to_param},
          user: {"id" => user.id, "name" => user.name, "role" => user.role},
          application_type: {"code" => "advertConsent"},
          changes: a_hash_including(
            "suffix" => ["ADVR", "ADVT"]
          ),
          automated: false
        ))
      end
    end
  end
end
