# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClasses::CommentFieldComponent, type: :component do
  let(:user) { create(:user, name: "Alice Smith") }
  let(:policy) { create(:policy) }

  let(:component) do
    described_class.new(policy: policy, comment: comment, policy_index: 1)
  end

  before { Current.user = user }

  context "when there is no comment" do
    let(:comment) { nil }

    before { render_inline(component) }

    it "renders empty field" do
      expect(page).to have_field("Add comment", with: "")
    end
  end

  context "when there is a comment" do
    let(:comment) do
      create(
        :comment,
        commentable: policy,
        created_at: DateTime.new(2022, 12, 19),
        text: "test"
      )
    end

    before { render_inline(component) }

    it "renders field with existing comment" do
      expect(page).to have_field(
        "Comment added on 19 Dec 2022 by Alice Smith",
        with: "test"
      )
    end
  end

  context "when the form is invalid" do
    let(:comment) { nil }

    before do
      policy.update(status: nil, comments_attributes: [{ text: "test" }])
      render_inline(component)
    end

    it "renders field with submitted text" do
      expect(page).to have_field("Add comment", with: "test")
    end
  end

  context "when an invalid blank value has been submitted" do
    let!(:comment) do # rubocop:disable RSpec/LetSetup
      create(
        :comment,
        commentable: policy,
        created_at: DateTime.new(2022, 12, 19),
        text: "test"
      )
    end

    before do
      policy.update(comments_attributes: [{ text: "" }])
      render_inline(component)
    end

    it "renders error message" do
      expect(page).to have_content("can't be blank")
    end

    it "renders field with submitted blank text" do
      expect(page).to have_field(
        "Comment added on 19 Dec 2022 by Alice Smith",
        with: ""
      )
    end
  end
end
