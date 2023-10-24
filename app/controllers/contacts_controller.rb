# frozen_string_literal: true

class ContactsController < AuthenticationController
  before_action :set_contacts

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_contacts
    @contacts = Contact.search(params[:q], **search_options)
  end

  def search_options
    {local_authority: current_local_authority, category: params[:category]}
  end
end
