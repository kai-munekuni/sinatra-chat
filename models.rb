require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection('sqlite3:db/development.db')
end


class User < ActiveRecord::Base
  has_secure_password
  validates :name, :password, presence: true
  validates :name, uniqueness: true, format: { with: /\A\w+\z/, message: "英数字のみが使えます" }
  validates :password, format: { with: /\A\w+\z/, message: "英数字のみが使えます" }
  has_many :rooms, through: :participants
  has_many :contributions
end

class Contribution < ActiveRecord::Base
  validates :content, presence: true
  belongs_to :user
  belongs_to :room
end

class Room < ActiveRecord::Base
  has_many :contributions
  has_many :users, through: :participants
end

class Participant < ActiveRecord::Base
end