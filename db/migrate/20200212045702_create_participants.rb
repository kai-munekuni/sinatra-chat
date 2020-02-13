class CreateParticipants < ActiveRecord::Migration[5.2]
  def change
    create_table :participants do |t|
      t.references :user
      t.references :room
      t.timestamps null: false
    end
  end
end
