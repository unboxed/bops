# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  let(:local_authority) { create(:local_authority) }
  let(:enforcement) { create(:enforcement) }
  let(:case_record) { create(:case_record, caseable: enforcement, local_authority:) }

  subject(:task) do
    described_class.new(
      name: "Initial task",
      status: :not_started,
      parent: case_record,
      slug: "initial-task"
    )
  end

  it "is valid with valid attributes" do
    expect(task).to be_valid
  end

  it "is invalid without a name" do
    task.name = nil

    expect {
      task.valid?
    }.to raise_error(ActiveModel::StrictValidationFailed, "Name can't be blank")
  end

  it "is invalid without a slug" do
    task.slug = nil

    expect {
      task.valid?
    }.to raise_error(ActiveModel::StrictValidationFailed, "Slug can't be blank")
  end

  it "enforces uniqueness of name scoped to parent" do
    task.save!
    duplicate = described_class.new(
      name: "Initial task",
      parent: case_record,
      slug: "initial-task"
    )

    expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows same name under a different parent" do
    first_parent = create(:case_record, caseable: create(:enforcement))
    second_parent = create(:case_record, caseable: create(:enforcement))

    Task.create!(
      name: "Shared name",
      parent: first_parent,
      slug: "#{first_parent}/shared-name"
    )

    other_task = Task.new(
      name: "Shared name",
      parent: second_parent,
      slug: "#{second_parent}/shared-name"
    )

    expect(other_task).to be_valid
  end

  describe "#action_required" do
    before { task.save! }

    it "sets the status to action_required" do
      expect { task.action_required }.to change(task, :status).from("not_started").to("action_required")
    end

    it "returns true on success" do
      expect(task.action_required).to be true
    end
  end

  describe "#action_required!" do
    before { task.save! }

    it "sets the status to action_required" do
      expect { task.action_required! }.to change(task, :status).from("not_started").to("action_required")
    end

    it "raises an error if the update fails" do
      allow(task).to receive(:update).and_return(false)

      expect { task.action_required! }.to raise_error(ActiveRecord::RecordNotSaved, /Unable to action_required/)
    end
  end

  describe "#start" do
    before { task.save! }

    it "sets the status to in_progress" do
      expect { task.start }.to change(task, :status).from("not_started").to("in_progress")
    end

    it "does not change the status if already completed" do
      task.update!(status: :completed)

      expect { task.start }.not_to change(task, :status)
    end
  end

  describe "#complete" do
    before { task.save! }

    it "sets the status to completed" do
      expect { task.complete }.to change(task, :status).from("not_started").to("completed")
    end
  end
end
