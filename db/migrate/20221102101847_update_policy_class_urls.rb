# frozen_string_literal: true

class UpdatePolicyClassUrls < ActiveRecord::Migration[6.1]
  def up
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-b-additions-etc-to-the-roof-of-a-dwellinghouse' WHERE section = 'B';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-c-other-alterations-to-the-roof-of-a-dwellinghouse' WHERE section = 'C';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-d-porches' WHERE section = 'D';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-e-buildings-etc-incidental-to-the-enjoyment-of-a-dwellinghouse' WHERE section = 'E';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-f-hard-surfaces-incidental-to-the-enjoyment-of-a-dwellinghouse' WHERE section = 'F';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-g-chimneys-flues-etc-on-a-dwellinghouse' WHERE section = 'G';"
  end

  def down
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-a-enlargement-improvement-or-other-alteration-of-a-dwellinghouse' WHERE section = 'B';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-c-other-alterations-to-the-roof-of-a-dwellinghouse/made' WHERE section = 'C';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-d-porches/made' WHERE section = 'D';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-e-buildings-etc-incidental-to-the-enjoyment-of-a-dwellinghouse/made' WHERE section = 'E';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-f-hard-surfaces-incidental-to-the-enjoyment-of-a-dwellinghouse/made' WHERE section = 'F';"
    execute "UPDATE policy_classes SET url = 'https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-g-chimneys-flues-etc-on-a-dwellinghouse/made' WHERE section = 'G';"
  end
end
