# frozen_string_literal: true

Rails.application.routes.draw do
  extend BopsCore::Routing

  get :healthcheck, to: proc { [200, {}, %w[OK]] }

  applicants_domain do
    draw :applicants
  end

  bops_domain do
    draw :bops
  end

  direct :notify_guide do
    "https://oasis-marsupial-465.notion.site/Guide-to-GOV-UK-Notify-set-up-7c18a8f3d43444d098c1f79eab48016c"
  end

  direct :planning_application_assessment_summary_of_advice do |pa|
    pa.summary_of_advice.present? ?
      [:edit, pa, :assessment, pa.summary_of_advice, category: :site_description] :
      [:new, pa, :assessment, :assessment_detail, category: :site_description]
  end
end
