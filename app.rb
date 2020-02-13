require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'


set :server, 'thin'
set :sockets, []
enable :sessions

default_user_img_url = "https://res.cloudinary.com/djx38nyqx/image/upload/v1581414480/images.png"

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

def upload_image(file)
  unless file
    return default_user_img_url
  end
  tempfile = file[:tempfile]
  upload = Cloudinary::Uploader.upload(tempfile.path)
  return upload['url']
end


get '/' do
  @scheme = ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
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
        img_url: upload_image(params[:file])
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

get '/websocket' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
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

not_found do
  status 404
  erb :oops
end