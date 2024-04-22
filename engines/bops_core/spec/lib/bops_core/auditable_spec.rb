# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::Auditable do
  subject do
    Class.new do
      include BopsCore::Auditable

      def payload_for_event
        {foo: "bar"}
      end
    end.new
  end

  describe "#audit" do
    shared_examples_for "#audit" do
      context "and a block is not given" do
        it "sends an audit event" do
          expect {
            subject.audit("event.scope", payload)
          }.to have_audit("event.scope").with_payload(foo: "bar")
        end
      end

      context "and a block is given" do
        it "sends an audit event" do
          expect {
            subject.audit("event.scope", payload) do |payload|
              payload[:bar] = "baz"
            end
          }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
        end
      end
    end

    context "when the payload is a hash" do
      let(:payload) { {foo: "bar"} }

      include_examples "#audit"
    end

    context "when the payload is a proc" do
      let(:payload) { -> { {foo: "bar"} } }

      include_examples "#audit"
    end

    context "when the payload is a symbol" do
      let(:payload) { :payload_for_event }

      include_examples "#audit"
    end
  end
end
