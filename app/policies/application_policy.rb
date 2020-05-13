# frozen_string_literal: true

class ApplicationPolicy
  class_attribute :viewers
  self.viewers = []

  attr_reader :user, :record

  delegate :assessor?, :reviewer?, :admin?, to: :user

  def initialize(user, record)
    @user = user
    @record = record
  end

  def viewer?
    signed_in_viewer?
  end

  # All of the primary actions by default to viewer
  alias_method :index?, :viewer?
  alias_method :show?, :viewer?
  alias_method :create?, :viewer?
  alias_method :new?, :viewer?
  alias_method :update?, :viewer?
  alias_method :edit?, :viewer?
  alias_method :destroy?, :viewer?

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
    %w[viewer].each do |type|
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
