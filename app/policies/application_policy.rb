# frozen_string_literal: true

class ApplicationPolicy
  class_attribute :viewers
  class_attribute :editors

  self.viewers = []
  self.editors = []

  attr_reader :user, :record

  delegate :assessor?, :reviewer?, to: :user

  def initialize(user, record)
    @user = user
    @record = record
  end

  def editor?
    signed_in_editor?
  end

  alias_method :index?, :editor?
  alias_method :show?, :editor?
  alias_method :create?, :editor?
  alias_method :new?, :editor?
  alias_method :update?, :editor?
  alias_method :edit?, :editor?
  alias_method :destroy?, :editor?
  alias_method :cancel?, :editor?

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

private

  def signed_in?
    user.present?
  end

  # Create two sets of methods dynamically. Examples:
  #
  # `signed_in_viewer?` and `is_viewer?`
  #
  # The `signed_in_...?` style methods check if the user is signed in. these
  # are likely to be overriden by implementing classes.
  #
  # The `is_...?` style methods are used by the `signed_in_...` methods, and
  # are included so that any overriding method can call `is_viewer? rather
  # than having to re-implement the check of the array every time.
  #
  %w[viewer editor].each do |type|
    class_eval <<-RUBY
        def signed_in_#{type}?
          signed_in? && is_#{type}?
        end
        def is_#{type}?
          #{type}s.include?(user.role)
        end
    RUBY
  end
end
