# frozen_string_literal: true

module BopsAdmin
  class TokensController < AccessController
    before_action :set_tokens, only: %i[index]
    before_action :build_token, only: %i[new create]
    before_action :set_token, only: %i[edit update destroy]

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @token.save
          format.html { render :show }
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @token.update(token_params)
          format.html do
            redirect_to tokens_url, notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        format.html do
          if @token.revoke!
            redirect_to tokens_url, notice: t(".success")
          else
            redirect_to tokens_url, notice: t(".failure")
          end
        end
      end
    end

    private

    def set_tokens
      @tokens = current_local_authority.api_users.by_name
    end

    def build_token
      @token = current_local_authority.api_users.new(token_params)
    end

    def set_token
      @token = current_local_authority.api_users.find(params[:id])
    end

    def token_params
      params.fetch(:token, {}).permit(*token_attributes, permissions: [], file_downloader_attributes:)
    end

    def token_attributes
      %i[name service]
    end

    def file_downloader_attributes
      %i[type username password token key value]
    end
  end
end
