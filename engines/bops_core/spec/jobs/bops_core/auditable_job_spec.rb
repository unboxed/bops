# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::AuditableJob, type: :job do
  context "when there is no default payload" do
    let(:application_job) do
      Class.new(ActiveJob::Base) do
        include BopsCore::AuditableJob
      end
    end

    context "and the payload is a hash" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: {foo: "bar"}

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar")
      end
    end

    context "and the payload is a proc" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: -> { {foo: "bar"} }

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar")
      end
    end

    context "and the payload is a symbol" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: :payload_for_event

          def perform
          end

          def payload_for_event
            {foo: "bar"}
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar")
      end
    end
  end

  context "when the default payload is a hash" do
    let(:application_job) do
      Class.new(ActiveJob::Base) do
        include BopsCore::AuditableJob

        self.audit_payload = {bar: "baz"}
      end
    end

    context "and the payload is a hash" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: {foo: "bar"}

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a proc" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: -> { {foo: "bar"} }

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a symbol" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: :payload_for_event

          def perform
          end

          def payload_for_event
            {foo: "bar"}
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end
  end

  context "when the default payload is a proc" do
    let(:application_job) do
      Class.new(ActiveJob::Base) do
        include BopsCore::AuditableJob

        self.audit_payload = -> { {bar: "baz"} }
      end
    end

    context "and the payload is a hash" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: {foo: "bar"}

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a proc" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: -> { {foo: "bar"} }

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a symbol" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: :payload_for_event

          def perform
          end

          def payload_for_event
            {foo: "bar"}
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end
  end

  context "when the default payload is a symbol" do
    let(:application_job) do
      Class.new(ActiveJob::Base) do
        include BopsCore::AuditableJob

        self.audit_payload = :default_payload_for_event

        def default_payload_for_event
          {bar: "baz"}
        end
      end
    end

    context "and the payload is a hash" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: {foo: "bar"}

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a proc" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: -> { {foo: "bar"} }

          def perform
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end

    context "and the payload is a symbol" do
      let(:job) do
        Class.new(application_job) do
          audit "event.scope", payload: :payload_for_event

          def perform
          end

          def payload_for_event
            {foo: "bar"}
          end
        end
      end

      it "sends an audit event when the job is performed" do
        expect {
          job.perform_now
        }.to have_audit("event.scope").with_payload(foo: "bar", bar: "baz")
      end
    end
  end
end
