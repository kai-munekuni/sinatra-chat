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
  has_many :participants
  has_many :rooms, through: :participants
  has_many :contributions
end

class Contribution < ActiveRecord::Base
  validates :content, presence: true
  belongs_to :user
  belongs_to :room
end

class Room < ActiveRecord::Base
  has_many :participants
  has_many :contributions
  has_many :users, through: :participants


  def self.create_talk(id, companion_id)
    rooms = Participant.where("user_id = ? OR user_id = ?", id, companion_id).select(:id)
    puts rooms
    if rooms.count != rooms.uniq.count
      return
    end
    room = Room.create()
    Participant.create([{room_id:room.id, user_id: companion_id}, {room_id:room.id, user_id:id}])
  end

  def self.companion_id(room_id, id)
    companion_id = Participant.where(room_id:room_id).where.not(user_id:id)[0].user_id
    return companion_id
  end
end

class Participant < ActiveRecord::Base
  belongs_to :room
  belongs_to :user
end