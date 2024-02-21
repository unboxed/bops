# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationJob do
  describe "saving and restoring the current user" do
    let(:user) { create(:user, name: "Background User") }
    let(:buffer) { StringIO.new }
    let(:logs) { buffer.string }

    before do
      Current.user = user
      ActiveJob::Base.logger = Logger.new(buffer)

      stub_const("MyApplicationJob", job_class)
    end

    context "a job with no arguments" do
      let(:job_class) do
        Class.new(::ApplicationJob) do
          def perform
            logger.info <<~INFO
              Performed #{self.class.name} for #{Current.user.name} with arguments: []
            INFO
          end
        end
      end

      it "performs the job" do
        perform_enqueued_jobs {
          MyApplicationJob.perform_later
        }

        expect(logs).to include <<~LOGS
          INFO -- : Performed MyApplicationJob for Background User with arguments: []
        LOGS
      end
    end

    context "a job with positional arguments" do
      let(:job_class) do
        Class.new(::ApplicationJob) do
          def perform(positional)
            logger.info <<~INFO
              Performed #{self.class.name} for #{Current.user.name} with arguments: [#{positional.inspect}]
            INFO
          end
        end
      end

      it "performs the job" do
        perform_enqueued_jobs {
          MyApplicationJob.perform_later("positional")
        }

        expect(logs).to include <<~LOGS
          INFO -- : Performed MyApplicationJob for Background User with arguments: ["positional"]
        LOGS
      end
    end

    context "a job with keyword arguments" do
      let(:job_class) do
        Class.new(::ApplicationJob) do
          def perform(keyword:)
            logger.info <<~INFO
              Performed #{self.class.name} for #{Current.user.name} with arguments: [keyword: #{keyword.inspect}]
            INFO
          end
        end
      end

      it "performs the job" do
        perform_enqueued_jobs {
          MyApplicationJob.perform_later(keyword: "keyword")
        }

        expect(logs).to include <<~LOGS
          INFO -- : Performed MyApplicationJob for Background User with arguments: [keyword: "keyword"]
        LOGS
      end
    end

    context "a job with mixed arguments" do
      let(:job_class) do
        Class.new(::ApplicationJob) do
          def perform(positional, keyword:)
            logger.info <<~INFO
              Performed #{self.class.name} for #{Current.user.name} with arguments: [#{positional.inspect}, keyword: #{keyword.inspect}]
            INFO
          end
        end
      end

      it "performs the job" do
        perform_enqueued_jobs {
          MyApplicationJob.perform_later("positional", keyword: "keyword")
        }

        expect(logs).to include <<~LOGS
          INFO -- : Performed MyApplicationJob for Background User with arguments: ["positional", keyword: "keyword"]
        LOGS
      end
    end
  end
end
