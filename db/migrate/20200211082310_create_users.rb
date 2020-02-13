class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.string :img_url, :default => "https://res.cloudinary.com/djx38nyqx/image/upload/v1581414480/images.png"
      t.timestamps null: false
    end
  end
end
