class TweetsController < ApplicationController
  before_filter :verify_login

  def index
    redirect_to :action => :new
  end

  def new
  end

  def create
    tweet = twitter_client.update(params[:tweet])
    redirect_to :action => :new
  end
end
