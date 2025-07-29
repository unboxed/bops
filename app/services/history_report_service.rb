# frozen_string_literal: true

class HistoryReportService
  attr_reader :planning_application, :client

  def initialize(planning_application)
    @planning_application = planning_application
    @client = OpenAI::Client.new(
      access_token: "xxxxxx"
    )
  end

  def call
    report = @planning_application.history_report || @planning_application.build_history_report

    begin
      response = fetch_planning_history_response
      report.raw = response
      report.refreshed_at = Time.current
      report.save!
    rescue => e
      Rails.logger.error("[HistoryReportService] Error generating history report: #{e.message}")
      report.error_message = e.message
      report.save!
    end

    report
  end

  private

  def fetch_planning_history_response
    prompt = build_prompt

    response = client.chat(
      parameters: {
        model: "gpt-4o",
        temperature: 0.2,
        messages: [
          {role: "system", content: "You are a helpful assistant generating structured planning history reports as JSON."},
          {role: "user", content: prompt}
        ]
      }
    )

    unless response.dig("choices", 0, "message", "content")
      raise "No response content from OpenAI"
    end

    response.dig("choices", 0, "message", "content")
  rescue JSON::ParserError => e
    raise "Failed to parse OpenAI response as JSON: #{e.message}"
  rescue OpenAI::Error => e
    raise "OpenAI API error: #{e.message}"
  end

  def build_prompt
    <<~PROMPT
      Please generate a structured planning history report for the following property:

      Address: #{planning_application.full_address}
      UPRN: #{planning_application.uprn}

      The report should include:
      - All relevant planning applications (approved, refused, withdrawn, pending)
      - Appeal decisions
      - Enforcement notices
      - Lawful development certificates
      - Site constraints (conservation area, listed status, flood risk, TPOs)
      - Applicable planning policies (local plan, SPDs, London Plan, NPPF)
      - Notable neighbouring applications
      - Any planning conditions still in force

      Please return only a valid JSON object. Do not wrap it in triple backticks or markdown formatting.
      Use direct links where documents are referenced.

      The JSON should follow this high-level structure:
        {
          "address": "...",
          "planning_applications": [...],
          "appeals": [...],
          "enforcement_notices": [...],
          "lawful_development_certificates": [...],
          "site_constraints": {...},
          "planning_policy": {...},
          "neighbouring_applications": [...],
          "active_conditions": [...],
          "archive_access": {...}
        }
    PROMPT
  end
end
