class CreateDrinksUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :drinks_users do |t|
      t.integer :user_id
      t.integer :drink_id

      t.timestamps
    end
  end
end
