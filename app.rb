require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require "json"


set :server, 'thin'
set :sockets, {}
enable :sessions


Dotenv.load
Cloudinary.config do |config|
  config.cloud_name = ENV['CLOUD_NAME']
  config.api_key    = ENV['CLOUDINARY_API_KEY']
  config.api_secret = ENV['CLOUDINARY_API_SECRET']
end


before do
  if session[:user].nil?
    unless request.path == "/sign_in" || request.path == "/sign_up"
      redirect '/sign_up'
    end
  end
end

helpers do
    def current_user
      User.find_by(id: session[:user])
    end
end

def upload_user_image(file)
  unless file
    return "https://res.cloudinary.com/djx38nyqx/image/upload/v1581414480/images.png"
  end
  tempfile = file[:tempfile]
  upload = Cloudinary::Uploader.upload(tempfile.path)
  return upload['url']
end


get '/' do
  @scheme = ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
  @rooms = current_user.rooms
  erb :index
end

get "/sign_up" do
  erb :sign_up
end

post "/sign_up" do
  user = User.create(
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        img_url: upload_user_image(params[:file])
        )
  if user.persisted?
      session[:user] = user.id
  end
  redirect '/'
end

get "/sign_in" do
  erb :sign_in
end

post "/sign_in" do
  user = User.find_by(name: params[:name])
  if user && user.authenticate(params[:password])
      session[:user] = user.id
  end
  redirect '/'
end

get "/sign_out" do
  session[:user] = nil
  redirect '/'
end

get "/new" do
  @users = User.where.not(id: current_user.id)
  erb :new
end

post '/room/:id' do
  companion = User.find(params[:id])
  room = Room.create_talk(current_user.id, companion.id)
  redirect '/'
end

get '/room/:id' do
  @scheme = ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
  unless Participant.find_by(user_id: current_user.id, room_id: params[:id])
    redirect '/'
  end
  @room = Room.find(params[:id])
  @companion = User.find(Room.companion_id(params[:id],current_user.id))
  @contributions = @room.contributions.order(created_at: "ASC")
  erb :message
end

post '/message' do
  c = Contribution.create(content:params[:text], room_id: params[:room_id],user_id:current_user.id)
  if c
    status 200
    ws = settings.sockets[Room.companion_id(params[:room_id],current_user.id)]
    if ws
      ws.send(JSON.generate({type:"message",text:c.content}))
    end
    return c.content
  end
end


get '/websocket' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
        settings.sockets[current_user.id] = ws
      end
      ws.onmessage do |msg|
        settings.sockets.each do |s|
          s.send(msg)
        end
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end
