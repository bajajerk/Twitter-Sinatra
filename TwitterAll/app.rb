require 'sinatra'
require 'data_mapper'

enable :sessions

set :public_folder, File.dirname(__FILE__) + '/assets'


DataMapper.setup(:default, "sqlite:///#{Dir.pwd}/project.db")

class User
	include DataMapper::Resource
	property :id, Serial
	property :email, String
	property :password, String
end


class Tweet
	include DataMapper::Resource
	property :id, Serial
	property :user_id, Numeric
	property :content, Text


	def like_count
		Like.all(tweet_id: id).length
	end

	def liked_by user_id
		Like.all(tweet_id: id, user_id: user_id).length > 0
	end
end

class Like
	include DataMapper::Resource
	property :id, Serial
	property :user_id, Numeric
	property :tweet_id, Numeric
end

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
	if session[:user_id].nil?
		return redirect '/signin'
	end
	tweets = Tweet.all

	erb :index, locals: {tweets: tweets, user_id: session[:user_id]}
end

post '/create_tweet' do
	content = params[:content]
	tweet = Tweet.new
	tweet.content = content
	tweet.user_id = session[:user_id]
	tweet.save
	return redirect '/'
end

post '/like' do
	tweet_id = params[:tweet_id]
	like = Like.all(tweet_id: tweet_id, user_id: session[:user_id]).first

	unless like
		like = Like.new
		like.tweet_id = tweet_id
		like.user_id = session[:user_id]
		like.save
	else
		like.destroy
	end

	return redirect '/'

end



get '/signout' do
	session[:user_id] = nil
	return redirect '/'
end



get '/signin' do
	erb :signin, layout: false
end

post '/signin' do
	email = params["email"]
	password = params["password"]

	# users = User.all(email: email)

	# if users.length > 0 
	# 	user = users[0]
	# else
	# 	user = nil
	# end

	user = User.all(email: email).first

	puts user.class

	if user.nil?
		return redirect '/signup'
	else
		if user.password == password
			session[:user_id] = user.id
			return redirect '/'
		else
			return redirect '/signin'
		end

	end

	redirect '/signin'
end



get '/signup' do
	erb :signup
end

post '/signup' do
	email = params["email"]
	password = params["password"]

	user = User.all(email: email).first

	if user
		return redirect '/signup'
	else
		user = User.new
		user.email = email
		user.password = password
		user.save
		session[:user_id] = user.id
		return redirect '/'
	end
end



post '/delete' do
 	particularTweetid=params[:tweet_id]
 	particularTweet=Tweet.get(particularTweetid)
	particularTweet.destroy
	redirect '/'
end
  



