class UsersController < ApplicationController
  def info
    @result = Twitter.user(params[:name])
  end

  def timeline
    @timeline = twitter_client.friends_timeline
  end
end
