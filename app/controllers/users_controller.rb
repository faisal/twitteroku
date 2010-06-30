class UsersController < ApplicationController
  def info
    @result = Twitter.user(params[:name])
  end
end
