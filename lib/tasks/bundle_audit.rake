# frozen_string_literal: true

desc "Audit bundle for any known vulnerabilities"
task bundle_audit: :environment do
  unless system "bundle-audit check --update"
    exit 1
  end
end
