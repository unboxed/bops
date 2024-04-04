# frozen_string_literal: true

class AddCodePrefixAndSuffixColumns < ActiveRecord::Migration[7.1]
  def change
    change_table :reporting_types, bulk: true do |t|
      t.virtual :code_prefix, type: :text, as: "regexp_replace(code, '[0-9]+$', '')::text", stored: true
      t.virtual :code_suffix, type: :integer, as: "regexp_replace(code, '^[A-Z]+', '')::int", stored: true
    end

    add_index :reporting_types, %i[code_prefix code_suffix]
  end
end
