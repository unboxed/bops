class AddCodePrefixAndSuffixColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :reporting_types, :code_prefix, :virtual, type: :text, as: "regexp_replace(code, '[0-9]+$', '')::text", stored: true
    add_column :reporting_types, :code_suffix, :virtual, type: :integer, as: "regexp_replace(code, '^[A-Z]+', '')::int", stored: true

    add_index :reporting_types, %i[code_prefix code_suffix]
  end
end
