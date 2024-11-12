class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
