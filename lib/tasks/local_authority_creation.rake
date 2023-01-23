# frozen_string_literal: true

require "optparse"

namespace :local_authority do |args|
  desc "Creates local authority with given name: rake local_authority:create"
  # environment is required to have access to Rails models
  task create: :environment do |_task|
    broadcast "LocalAuthority: #{LocalAuthority.count}"

    options = {}
    opts = OptionParser.new
    opts.banner = "Usage: rake local_authority:create [options]"
    opts.on("-sd", "--subdomain ARG", String) { |subdomain| options[:subdomain] = subdomain }
    opts.on("-cc", "--council_code ARG", String) { |council_code| options[:council_code] = council_code }
    opts.on("-sn", "--signatory_name ARG", String) { |signatory_name| options[:signatory_name] = signatory_name }
    opts.on("-sjt", "--signatory_job_title ARG", String) do |signatory_job_title|
      options[:signatory_job_title] = signatory_job_title
    end
    opts.on("-ep", "--enquiries_paragraph ARG", String) do |enquiries_paragraph|
      options[:enquiries_paragraph] = enquiries_paragraph
    end
    opts.on("-ea", "--email_address ARG", String) { |email_address| options[:email_address] = email_address }
    opts.on("-fe", "--feedback_email ARG", String) { |feedback_email| options[:feedback_email] = feedback_email }
    opts.on("-ae", "--admin_email ARG", String) { |admin_email| options[:admin_email] = admin_email }

    args = opts.order!(ARGV) {}
    opts.parse!(args)

    broadcast "Creating local_authority: #{options[:subdomain]}"

    LocalAuthorityCreationService.new(options).call

    broadcast "LocalAuthority: #{LocalAuthority.count}"
    broadcast "End"
  end

  def broadcast(message)
    puts message
    Rails.logger.info message
  end
end
