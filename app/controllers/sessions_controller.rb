class SessionsController < ApplicationController
  def new
  end

  def create
    oauth.set_callback_url url_for(:controller => :sessions, :action => :write)

    session[:rtoken_key]  = oauth.request_token.token
    session[:rtoken_secret] = oauth.request_token.secret

    auth_redirect = oauth.request_token.authorize_url

    # work around bug in Twitter gem 0.9.8
    # see http://github.com/jnunemaker/twitter/issuesearch?state=open&q=http#issue/46
    if !auth_redirect.match(/^http/)
      redirect_to 'https://' + auth_redirect
    else
      redirect_to auth_redirect
    end
  end

  def destroy
    reset_session
    redirect_to :controller => :sessions, :action => :new
  end

  def write
    oauth.authorize_from_request(session[:rtoken_key], session[:rtoken_secret], params[:oauth_verifier])

    user = Twitter::Base.new(oauth).verify_credentials
    session[:rtoken_key] = nil
    session[:rtoken_secret] = nil
    session[:atoken_key] = oauth.access_token.token
    session[:atoken_secret] = oauth.access_token.secret

    sign_in(user)
    redirect_back_or root_path
  end
end
