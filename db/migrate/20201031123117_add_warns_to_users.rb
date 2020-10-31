class AddWarnsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :warns, :integer, default: 0, null: false
  end
end
