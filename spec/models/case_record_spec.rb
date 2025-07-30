# frozen_string_literal: true

require "rails_helper"

RSpec.describe CaseRecord, type: :model do
  let(:local_authority) { create(:local_authority) }
  let(:enforcement) { create(:enforcement) }

  describe "#load_tasks!" do
    let(:case_record) do
      described_class.new(
        local_authority:,
        caseable: create(:enforcement)
      )
    end

    it "loads tasks from the workflow" do
      expect {
        case_record.save!
      }.to change(Task, :count).by_at_least(1)

      expect(case_record.tasks.map(&:name)).to eq(
        ["Check breach report", "Investigate and decide", "Review recommendation", "Serve notice and monitor compliance", "Process an appeal"]
      )
    end

    it "builds correct task hierarchy" do
      case_record.save!

      top_task = case_record.tasks.find_by(name: "Investigate and decide")
      child_task = top_task.tasks.find_by(name: "Update site and owner details")
      grandchild_task = child_task.tasks.find_by(name: "Update site location")

      expect(child_task.parent).to eq(top_task)
      expect(grandchild_task.parent).to eq(child_task)
    end

    it "assigns default status and position" do
      case_record.save!

      task = case_record.tasks.find_by(name: "Check breach report")

      expect(task.status).to eq("not_started")
      expect(task.position).to eq(0)
    end

    it "prevents save if workflow is missing" do
      TaskLoader.clear_cache!
      allow(YAML).to receive(:load_file).and_return([])

      expect {
        case_record.save!
      }.to raise_error(ActiveRecord::RecordNotSaved, /Failed to save/)
    end

    it "does not create duplicate tasks if called twice" do
      case_record.save!
      expect {
        case_record.save!
      }.not_to change(Task, :count)
    end
  end

  describe "#top_level_tasks" do
    before do
      allow_any_instance_of(CaseRecord).to receive(:load_tasks!).and_return(nil)
    end
    let(:case_record) { described_class.create!(local_authority:, caseable: enforcement) }
    let!(:task1) { create(:task, name: "A", position: 1, parent: case_record, slug: "a") }
    let!(:task2) { create(:task, name: "B", position: 0, parent: case_record, slug: "b") }

    it "returns tasks ordered by position" do
      expect(case_record.tasks.map(&:name)).to eq(%w[B A])
    end
  end

  describe "#find_task_by_path!" do
    let(:phase) { Task.new(name: "Phase", tasks: [step]) }
    let(:step) { Task.new(name: "Step", tasks: [sub_step]) }
    let(:sub_step) { Task.new(name: "Sub Step") }
    let(:case_record) { CaseRecord.new(local_authority:, caseable: enforcement, tasks: [phase]) }

    before do
      case_record.save!
    end

    it "returns the correct task from a single-segment slug" do
      expect(case_record.find_task_by_path!("phase")).to eq(phase)
    end

    it "returns the correct nested task from a multi-segment slug" do
      expect(case_record.find_task_by_path!("phase", "step", "sub-step")).to eq(sub_step)
    end

    it "raises if the slug path is invalid" do
      expect {
        case_record.find_task_by_path!("phase", "missing")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
