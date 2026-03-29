class RemoveBalanceFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :users, name: "positive_balance" if check_constraint_exists?(:users, name: "positive_balance")
    remove_column :users, :balance, :decimal, precision: 12, scale: 2, null: false, default: 0
  end
end
