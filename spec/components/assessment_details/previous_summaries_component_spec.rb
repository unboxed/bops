# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetails::PreviousSummariesComponent, type: :component do
  let(:planning_application) { create(:planning_application) }
  let(:assessor) { create(:user, :assessor, name: "Alice Smith") }
  let(:reviewer) { create(:user, :reviewer, name: "Bella Jones") }

  let(:assessment_detail1) do
    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      user: assessor,
      entry: "version 1",
      created_at: Time.zone.local(2022, 11, 28, 10, 15)
    )
  end

  let(:assessment_detail2) do
    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      user: assessor,
      entry: "version 2",
      created_at: Time.zone.local(2022, 11, 29, 10, 15)
    )
  end

  before do
    Current.user = reviewer

    create(
      :comment,
      commentable: assessment_detail1,
      text: "comment 1",
      created_at: Time.zone.local(2022, 11, 28, 10, 30)
    )

    create(
      :comment,
      commentable: assessment_detail2,
      text: "comment 2",
      created_at: Time.zone.local(2022, 11, 29, 10, 30)
    )

    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      user: assessor,
      entry: "version 3",
      created_at: Time.zone.local(2022, 11, 30, 10, 15)
    )

    component = described_class.new(
      planning_application:,
      category: :summary_of_work
    )

    render_inline(component)
  end

  it "renders first summary" do
    expect(page).to have_content("Alice Smith created summary of works")
    expect(page).to have_content("28 November 2022 10:15")
    expect(page).to have_content("version 1")
  end

  it "renders first comment" do
    expect(page).to have_content("Bella Jones marked this for review")
    expect(page).to have_content("28 November 2022 10:30")
    expect(page).to have_content("comment 1")
  end

  it "renders second summary" do
    expect(page).to have_content("Alice Smith updated summary of works")
    expect(page).to have_content("29 November 2022 10:15")
    expect(page).to have_content("version 2")
  end

  it "renders second comment" do
    expect(page).to have_content("Bella Jones marked this for review")
    expect(page).to have_content("29 November 2022 10:30")
    expect(page).to have_content("comment 2")
  end

  it "does not render third summary" do
    expect(page).not_to have_content("version 3")
  end
end
