class AddLastUntappdCheckinAtToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :last_untappd_checkin_at, :datetime
  end
end
