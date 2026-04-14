# frozen_string_literal: true

class AddConsultationPostalAddressToLocalAuthorities < ActiveRecord::Migration[8.1]
  class LocalAuthority < ActiveRecord::Base; end

  CONSULTATION_POSTAL_ADDRESSES = {
    "lambeth" => "Planning department\nLambeth Council\nP.O. Box 734\nWinchester\nSO23 5DG",
    "southwark" => "Planning department\nSouthwark Council\nPO BOX 64529\nLondon \nSE1P 5LX",
    "buckinghamshire" => "Planning department\nBuckinghamshire Council\nWalton Street Offices\nWalton Street\nAylesbury\nHP20 1UA",
    "gloucester" => "Planning department\nGloucester City Council\nPO Box 2017\nPershore\nWR10 9BJ",
    "medway" => "Planning department\nMedway Council\nGun Wharf\nDock Road\nChatham\nME4 4TR",
    "camden" => "Planning department\nLondon Borough of Camden 2nd Floor, 5 Pancras Square\nc/o Town Hall, Judd Street\nLondon\nWC1H 9JE"
  }

  def change
    add_column :local_authorities, :consultation_postal_address, :string

    up_only do
      LocalAuthority.reset_column_information

      CONSULTATION_POSTAL_ADDRESSES.each do |subdomain, address|
        LocalAuthority.where(subdomain:).update!(consultation_postal_address: address)
      end
    end
  end
end
