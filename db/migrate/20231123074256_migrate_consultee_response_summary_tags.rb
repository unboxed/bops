# frozen_string_literal: true

class MigrateConsulteeResponseSummaryTags < ActiveRecord::Migration[7.0]
  class ConsulteeResponse < ActiveRecord::Base; end

  def up
    ConsulteeResponse
      .where(summary_tag: "no_objections")
      .update_all(summary_tag: "approved")

    ConsulteeResponse
      .where(summary_tag: "refused")
      .update_all(summary_tag: "objected")
  end

  def down
    ConsulteeResponse
      .where(summary_tag: "approved")
      .update_all(summary_tag: "no_objections")

    ConsulteeResponse
      .where(summary_tag: "objected")
      .update_all(summary_tag: "refused")
  end
end
