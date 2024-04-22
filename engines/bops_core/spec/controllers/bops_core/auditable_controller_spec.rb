# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::AuditableController, type: :controller do
  controller(ActionController::Base) do
    include BopsCore::AuditableController

    audit :create, event: "event.scope", payload: {foo: "bar"}

    def create
    end
  end

  it "sends an audit event for the create action" do
    expect {
      post :create
    }.to have_audit("event.scope").with_payload(foo: "bar")
  end
end
