# frozen_string_literal: true

module PlanningApplicationHelper
  def exclude_others?
    params[:q] == "exclude_others"
  end

  def role_name
    if current_user.assessor?
      t("user.officer_role")
    else
      t("user.manager_role")
    end
  end

  def proposed_or_existing(planning_application)
    planning_application.work_status == "proposed" ? "No" : "Yes"
  end

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def map_link(address)
    "https://google.co.uk/maps/place/#{CGI.escape(address)}"
  end

  def mapit_link(postcode)
    "https://mapit.mysociety.org/postcode/#{postcode.gsub(/\s+/, '').upcase}.html"
  end

  def display_number(proposal_details, element)
    proposal_details.find_index(element) + 1
  end

  def validation_request_summary(validation_requests, planning_application)
    if planning_application.invalidated?
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    elsif planning_application.validation_requests.none? && (planning_application.recommendable? || planning_application.closed_or_cancelled?)
      "This application had no validation requests"
    elsif planning_application.recommendable? || (planning_application.closed_or_cancelled? && planning_application.validation_requests.present?)
      "This application has #{pluralize(validation_requests.count(&:closed?), 'resolved validation request')}"
    else
      # FIXME: same body as first branch
      "This application has #{pluralize(validation_requests.count(&:open?),
                                        'unresolved validation request')} and #{pluralize(
                                          validation_requests.count(&:closed?), 'resolved validation request'
                                        )}"
    end
  end
end
