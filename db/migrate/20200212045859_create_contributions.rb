class CreateContributions < ActiveRecord::Migration[5.2]
  def change
    create_table :contributions do |t|
      t.references :room
      t.references :user
      t.string :content
      t.timestamps null: false
    end
  end
end
