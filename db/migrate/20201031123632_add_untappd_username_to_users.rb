class AddUntappdUsernameToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :untappd_username, :string
  end
end
