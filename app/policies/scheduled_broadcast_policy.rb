class ScheduledBroadcastPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner?
  end

  def create?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
