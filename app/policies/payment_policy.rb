class PaymentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def show?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
