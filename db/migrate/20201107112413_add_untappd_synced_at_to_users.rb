class AddUntappdSyncedAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :untappd_synced_at, :datetime
  end
end
