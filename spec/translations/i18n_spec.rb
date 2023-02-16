# frozen_string_literal: true

require "i18n/tasks"

RSpec.describe I18n do
  let(:i18n) { I18n::Tasks::BaseTask.new }
  let(:missing_keys) { i18n.missing_keys }
  let(:unused_keys) { i18n.unused_keys }
  let(:inconsistent_interpolations) { i18n.inconsistent_interpolations }
  let(:non_normalized_paths) { i18n.non_normalized_paths }

  it "does not have missing keys", skip: "pending" do
    error_message = "Missing #{missing_keys.leaves.count} i18n keys, run 'i18n-tasks missing' to show them"
    expect(missing_keys).to be_empty, error_message
  end

  it "does not have unused keys", skip: "pending" do
    error_message = "#{unused_keys.leaves.count} unused i18n keys, run 'i18n-tasks unused' to show them"
    expect(unused_keys).to be_empty, error_message
  end

  it "files are normalized" do
    error_message = "The following files need to be normalized:\n#{non_normalized_paths.join("\n")}\nPlease run 'i18n-tasks normalize' to fix"
    expect(non_normalized_paths).to be_empty, error_message
  end

  it "does not have inconsistent interpolations" do
    error_message = "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\nRun 'i18n-tasks check-consistent-interpolations' to show them"
    expect(inconsistent_interpolations).to be_empty, error_message
  end
end
