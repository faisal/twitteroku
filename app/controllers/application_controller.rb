# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery

  rescue_from OAuth::Unauthorized, :with => :force_login
  rescue_from Twitter::Unauthorized, :with => :force_login
  rescue_from ActionController::InvalidAuthenticityToken, :with => :force_login

  protected
    def oauth
      # This sets up the basic oauth object but does not ask for a Request Token until you
      # call request_token on the oauth object

      # OAuth deals with a nil endpoint by using its default. However, if we have
      # Apigee then Apigee will create a APIGEE_TWITTER_API_ENDPOINT environment
      # variable, which we sould use. For local testing, declare that variable yourself
      # based on what the Apigee plugin assigned on Heroku.
      if !ENV['APIGEE_TWITTER_API_ENDPOINT'].nil?
        api_endpoint = 'http://' + ENV['APIGEE_TWITTER_API_ENDPOINT']
      else
        api_endpoint = nil
      end

      @oauth ||= Twitter::OAuth.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'], :api_endpoint => api_endpoint)
    end

    def twitter_client
      oauth.authorize_from_access(session[:atoken_key], session[:atoken_secret])
      Twitter::Base.new(oauth)
    end

    def force_login(exception)
      # If something goes wrong, flush the session and start over.
      # Usually called as a result of a caught exception.

      reset_session
      flash[:error] = 'Credentials expired -- please sign in again.'
      redirect_to :controller => :sessions, :action => :new
    end

    def verify_login
      # If we have a screen_name we assume we're valid.
      # If not, start over.

      if !session[:screen_name]
        if request.get?
          session[:return_to] = request.request_uri
        end
        redirect_to :controller => :sessions, :action => :new
      end
    end

    def sign_in(user)
      if user
        session[:screen_name] = user.screen_name
      end
    end

    def redirect_back_or(default)
      session[:return_to] ||= params[:return_to]
      if session[:return_to]
        redirect_to(session[:return_to])
      else
        redirect_to(default)
      end
      session[:return_to] = nil
    end
end
