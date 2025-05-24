# frozen_string_literal: true

namespace :errors do
  desc "Precompile error pages into /public"
  task precompile: :environment do
    BopsCore::Errors.precompile
  end

  task clobber: :environment do
    BopsCore::Errors.clobber
  end
end

task "assets:precompile" => "errors:precompile"
task "assets:clobber" => "errors:clobber"
