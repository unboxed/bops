# frozen_string_literal: true

class AddAccessibiltyInformationToLocalAuthority < ActiveRecord::Migration[7.2]
  class LocalAuthority < ActiveRecord::Base; end

  ACCESSIBILITY_INFO = {
    "barnet" => ["The Planning Reception\n2nd Floor Barnet House\nWhetstone\nN20 0EJ", "020 8359 3000", "digitalplanning@barnet.gov.uk"],
    "buckinghamshire" => ["Directorate for Planning\nGrowth and Sustainability\nPlanning and Environment\nBuckinghamshire Council\nThe Gateway\nGatehouse Road\nAylesbury\nHP19 8FF", "0300 131 6000", "planning.digital@buckinghamshire.gov.uk"],
    "lambeth" => ["Planning\nLondon Borough of Lambeth\nPO Box 734\nWinchester\nSO23 5DG", "020 7926 1180", "digitalplanning@lambeth.gov.uk"],
    "medway" => ["Gun Wharf\nDock Road\nChatham\nKent\nME4 4TR", "01634 331 700", "planning.representations@medway.gov.uk"],
    "southwark" => ["Planning Department\nSouthwark Council\nPO BOX 64529\nLondon\nSE1P 5LX", "020 7525 5403", "digital.projects@southwark.gov.uk"],
    "newcastle" => ["Development Management\nCivic Centre\nNewcastle upon Tyne\nNE1 8QH", "0191 278 7878", "digitalplanning@newcastle.gov.uk"],
    "camden" => ["5 Pancras Sq\nLondon\nN1C 4AG", "020 7974 4444", "digitalplanning@camden.gov.uk"],
    "great-yarmouth" => ["Planning\nTown Hall\nHall Plain\nGreat Yarmouth\nNorfolk\nNR30 2QF", "01493 846 242", "plan@great-yarmouth.gov.uk"],
    "gloucester" => ["Gloucester City Council\nPO Box 2017\nPershore\nWR10 9BJ", "01452 396 787", "odpbops@gloucester.gov.uk"]
  }

  def change
    add_column :local_authorities, :accessibility_postal_address, :string
    add_column :local_authorities, :accessibility_phone_number, :string
    add_column :local_authorities, :accessibility_email_address, :string

    up_only do
      LocalAuthority.reset_column_information

      ACCESSIBILITY_INFO.each do |subdomain, (address, phone, email)|
        LocalAuthority.where(subdomain:).update!(
          accessibility_postal_address: address,
          accessibility_phone_number: phone,
          accessibility_email_address: email
        )
      end
    end
  end
end
