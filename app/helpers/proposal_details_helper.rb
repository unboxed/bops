# frozen_string_literal: true

module ProposalDetailsHelper
  def proposal_details_group_id(group)
    proposal_details_group_name(group).downcase.gsub(/[^0-9a-z]/i, "")
  end

  def proposal_details_group_title(group)
    proposal_details_group_name(group).downcase.underscore.humanize
  end

  def proposal_details_group_name(group)
    case group
    when "_root"
      t("proposal_details.main")
    when nil
      t("proposal_details.other")
    else
      group
    end
  end

  def proposal_detail_item(proposal_detail)
    tag.p(class: "govuk-body") do
      concat(proposal_detail_question(proposal_detail.question))
      concat(proposal_detail_responses(proposal_detail.responses))
      concat(proposal_detail_metadata(proposal_detail.metadata))
    end
  end

  def proposal_detail_question(question)
    tag.p(class: "govuk-body") { tag.strong(question) }
  end

  def proposal_detail_responses(responses)
    tag.p(class: "govuk-body") { responses.map(&:value).compact.join(", ") }
  end

  def proposal_detail_metadata(metadata)
    return if metadata.nil?

    tag.div do
      concat(proposal_detail_notes(metadata.notes))
      concat(proposal_detail_auto_answered(metadata.auto_answered))
      concat(proposal_detail_policy_refs(metadata.policy_refs))
    end
  end

  def proposal_detail_notes(notes)
    tag.p(tag.em(notes)) if notes.present?
  end

  def proposal_detail_auto_answered(auto_answered)
    tag.p(tag.em(t("proposal_details.auto_answered"))) if auto_answered.present?
  end

  def proposal_detail_policy_refs(policy_refs)
    return if policy_refs.blank?

    policy_refs.map do |policy_ref|
      if policy_ref.url.present?
        link_to(policy_ref.url, policy_ref.url, class: "govuk-link")
      else
        policy_ref.text
      end
    end.join(", ").html_safe # rubocop:disable Rails/OutputSafety
  end
end
