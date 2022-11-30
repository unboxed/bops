# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment Legislation" do
  let!(:default_local_authority) do
    create(
      :local_authority,
      :default,
      reviewer_group_email: "reviewers@example.com"
    )
  end

  let!(:planning_application) do
    create(
      :planning_application,
      local_authority: default_local_authority,
      created_at: DateTime.new(2022, 1, 1),
      public_comment: nil
    )
  end

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority: default_local_authority,
      name: "Alice Aplin"
    )
  end

  before do
    sign_in assessor
    visit root_path
  end

  it "shows assessed legislation on recommendation page" do
    visit(planning_application_path(planning_application))
    click_link("Check and assess")
    click_link("Add assessment area")
    choose("Part 1 - Development within the curtilage of a dwellinghouse")
    click_button("Continue")
    check("Class D - porches")
    click_button("Add classes")
    click_link("Part 1, Class D")
    choose("policy_class_policies_attributes_0_status_complies")
    choose("policy_class_policies_attributes_1_status_complies")
    choose("policy_class_policies_attributes_2_status_complies")
    choose("policy_class_policies_attributes_3_status_complies")
    choose("policy_class_policies_attributes_4_status_complies")
    choose("policy_class_policies_attributes_5_status_to_be_determined")
    click_button("Save and come back later")
    click_link("Application")
    click_link("Assess recommendation")

    expect(page).to have_content("To be determined")

    click_link("Part 1, Class D - porches")
    choose("policy_class_policies_attributes_5_status_does_not_comply")
    click_button("Save and come back later")
    click_link("Application")
    click_link("Assess recommendation")

    expect(page).to have_content("Does not comply")

    expect(page).to have_content(
      "Development is not permitted by Class D if the dwellinghouse is built under Part 20 of this Schedule (construction of new dwellinghouses)"
    )

    click_link("Part 1, Class D - porches")
    choose("policy_class_policies_attributes_5_status_complies")
    click_button("Save and come back later")
    click_link("Application")
    click_link("Assess recommendation")

    expect(page).to have_content("Complies")
  end

  context "when uncommented" do
    it "excludes 'more details' when complying or to_be_determined" do
      policy_class = create(:policy_class,
                            part: 1,
                            section: "T",
                            planning_application: planning_application)
      create(:policy,
             :complies,
             section: "1A",
             policy_class: policy_class)

      create(:policy,
             :to_be_determined,
             section: "1A",
             policy_class: policy_class)

      visit(new_planning_application_recommendation_path(planning_application))

      expect(page).to have_selector "h1", text: "Assess recommendation"
      expect(page).not_to have_content("View commented legislation for class T")
    end

    it "includes 'more details' when clause does not comply" do
      policy_class = create(:policy_class,
                            part: 1,
                            section: "T",
                            planning_application: planning_application)
      create(:policy,
             :does_not_comply,
             section: "1A",
             policy_class: policy_class)

      visit(new_planning_application_recommendation_path(planning_application))

      expect(page).to have_selector "h1", text: "Assess recommendation"
      expect(page).to have_content("View commented legislation for class T")
    end
  end

  context "when commented" do
    it "shows legislation paragraphs that comply" do
      policy_class = create(:policy_class,
                            part: 1,
                            section: "T",
                            planning_application: planning_application)
      policy = create(:policy,
                      :complies,
                      section: "1M",
                      policy_class: policy_class)

      create(:comment, commentable: policy)

      visit(new_planning_application_recommendation_path(planning_application))

      expect(page).to have_content("Complies")
      expect(page).to have_content("View commented legislation for class T")
    end
  end
end
