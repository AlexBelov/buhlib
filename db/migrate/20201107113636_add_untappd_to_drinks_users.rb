class AddUntappdToDrinksUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :drinks_users, :untappd, :boolean, default: false, null: false
  end
end
