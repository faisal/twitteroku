# Building a Twitter App on Heroku

This tutorial walks you through creating a basic Twitter app using Heroku. The app will be a fairly straigh-forward Rails app, with one tricky part (OAuth). We'll take it step by step.

This tutorial assumes you're already comfortable with Rails, and familiar with Heroku. This tutorial is focussed on the interactions you need to code to get your app to talk to Twitter. This isn't production-quality code, and it isn't particularly elegant.

## Contents

1. Setup
2. Querying User info
3. Searching Twitter
4. Interlude: understanding OAuth
5. Telling Twitter about your app
6. Telling your app about Twitter
6. Posting
7. Using Apigee
8. Other Notes and Resources

## 1. Setup

We'll use Heroku's [Bamboo](http://docs.heroku.com/bamboo) stack, which lets you use Rails 2.3.8 and [John Nunemaker](http://addictedtonew.com/)'s [Twitter gem](http://twitter.rubyforge.org/). There are a number of Twitter gems, but this one is fairly popular and works well on Heroku.

First, do the usual setup:

    $ rails titteroku
    $ cd twitteroku
    $ rm public/index.html
    $ rake db:migrate
    $ git init

Now create a .gems file declaring use of Rails 2.3.8 and the Twitter gem:

    rails -v 2.3.8
    twitter

Then, tell Rails to use the Twitter gem by putting a config.gem line in config/environment.erb.

    config.gem 'twitter'

Finally, commit the app and push it to Heroku:

    $ git add .
    $ git commit -m "my new Twitter app"
    $ heroku create --stack bamboo-ree-1.8.7
    $ git push heroku master

Now you're ready to get something working. From now on, we won't mention when to push to Heroku, so remember to <code>git push heroku master</code> when you want to see changes online.

## 2. Querying User Info

Querying public information doesn't require authentication, so we'll start by asking Twitter about a user.

First, create a controller that lets you get a specific user's information from Twitter.

    $ script/generate controller Users info

Now modify the info method to query Twitter, and put the results in the @results variable:

    def info
      @result = Twitter.user(params[:name])
    end

@result will be a hash with key value pairs for the different information Twitter is aware of for that user. What the API returns depends on what the system knows about, so make sure your apps can handle varying return values in that hash.

Now create app/views/users/index.html.erb and app/views/users/info.html.erb to set up the query and display the results.

app/views/users/index.html.erb:

    <p><% form_tag :action => 'info' do %>
      Let's find out about: @<%= text_field_tag :name %>
      <% end -%></p>

app/views/users/info.html.erb:

    <p>debug() info about:
      <img src="<%= @result['profile_image_url'] %>" valign="top">
      @<a href="http://www.twitter.com/<%= @result['screen_name'] %>"><%= @result['screen_name'] %></a>
      <%= @result['name'] %>)</p>
    <p><%= debug @result %></p>

The <code>debug</code> block shows you the structure of what was returned, and the paragraph above shows you an example of using it in a view.

Your app should now let you enter a user's screen name and get back their publicly listed information. Visit http://0.0.0.0:3000/user and enter 'heroku' to see what Twitter knows about @heroku.

## 3. Searching Twitter

Now let's search Twitter for all recent public tweets by or mentioning a specific user. This is similar to doing a search on the Twitter site, but it's available in your application.

We'll add the results of that search <code>app/views/users/info.html.erb</code>:

    <table>
      <tr><td>Who</td><td>What</td></tr>
      <% Twitter::Search.new('@'+params[:name]).each do |r| %><tr>
        <td>@<a href="http://www.twitter.com/<%= r['from_user'] %>"><%= r['from_user'] %></a></td>
        <td><%= r['text'] %></td>
      </tr><% end %>
    </table>

## 4. Interlude: Understanding OAuth

Now we're going to do something trickier -- post to Twitter from our app. The tricky part isn't the posting: it's that posting requires authentication and authorization. Twitter uses the OAuth system for authentication and authorization, which is more secure than passwords and easier for users to use, but a bit harder to code.

### Why

When apps need to talk to each other, they need a way to confirm that they're both working on behalf of the user and are allowed to do what the user wants. Many systems and apps handle this by asking the user to give up their login credentials to another site -- for example, when a site asks you to enter the userid and password to your email account. This compromises the other app (in this case, your mail) and it makes it difficult to undo the connection.

Instead, OAuth solves this problem by providing a way for the upstream app (in this case, Twitter) to keep track of what apps want access to the users' data, and lets the user give apps authorization for specific tasks.

A simple explanation is that the user goes to the app, the app authenticates itself with Twitter, Twitter confirms that the user wants to give the app Twitter access on the user's behalf, and Twitter allows the app to read from and write to Twitter. The user does not give the app their Twitter credentials, and the user can disable the app's Twitter access without having to change passwords.

### How

To keep things straight, this part will talk about YourApp, Twitter, and Jane User.

We'll also talk about a <code>Consumer Token</code>, <code>Request Token</code> and <code>Access Token</code>. Each token also has an associated secret, and the token/secret pair is used to perform a specific action:

1. The <code>Consumer Token</code> authenticates YourApp to Twitter in order to get a <code>Request Token</code>.
2. YourApp then uses the <code>Request Token</code> to ask Twitter to authenticate Jane User, producing an <code>Access Token</code>.
3. When Jane User does something in YourApp, YourApp uses the <code>Access Token</code> to show Twitter that YourApp is authorized to do this action on Jane User's behalf.

The workflow is:

1. As a developer, you'll create a <code>Consumer Token</code> for YourApp.
2. Jane User visits YourApp, which starts a new session.
3. YourApp uses the <code>Consumer Token</code> to get a <code>Request Token</code> for this session.
4. YourApp uses the <code>Request Token</code> to ask Twitter for an <code>Access Token</code> for Jane User's session.
5. Twitter makes sure Jane User is authenticated to Twitter, and that she's authorized YourApp to use Twitter on her behalf.
6. Twitter sends Jane User back to YourApp, with an <code>Access Token</code> for the three-way authorization.
7. Jane User uses YourApp, which uses the <code>Access Token</code> to ask Twitter to perform API call.

## 5. Telling Twitter About Your App

To allow authenticated access with Twitter, you'll need to register your app with Twitter.

Visit [http://dev.twitter.com/apps/new](http://dev.twitter.com/apps/new) and enter the details of your app.

- The Application Type should be Browser.
- The Application Name is the name that will be noted on tweets people post. The word "twitter" can't be part of the name.
- The Callback URL is the URL on your site that the user should be returned to after authentication. You can leave that blank for now, but eventually you'll want to set it to the URL for your app.
- You'll be posting to Twitter, so be sure to mark the Access Level as Read & Write.

You can change these fields later, so don't worry too much about the details right now.

## 6. Telling Your App About Twitter

When your app connects to Twitter it will need to confirm its identity to get a request token. To do this it will need the Consumer key and Consumer secret Twitter gave your app. Find your app at http://dev.twitter.com/apps, and copy down the Consumer key and Consumer secret.

The easiest way to use these is an app is to hardcode them into the code, but that's not a great idea -- it's less secure, and fairly inflexible. Instead, you can use environment variables, so you can easily switch if needed. This also lets you have different development and production apps registered with Twitter.

    $ export CONSUMER_KEY=[SomeLongStringHere]
    $ export CONSUMER_SECRET=[AnotherLongStringHere]

Now run script/server and your app will have access to the key and secret.

To give Heroku access to the string and secret, you'll need to use [Config vars](http://docs.heroku.com/config-vars).

    $ heroku config:add CONSUMER_KEY=[SomeLongStringHere] CONSUMER_SECRET=[AnotherLongStringHere]

_Remember: the LongStringHere fields are placeholders for the Consumer key and Consumer secret provided by your Twitter app's [information page](http://dev.twitter.com/apps)._

If you've set the environment variables locally and are using the same Twitter app on Heroku, you can set the environment variables to match by doing:

    $ heroku config:add CONSUMER_KEY=$CONSUMER_KEY CONSUMER_SECRET=$CONSUMER_SECRET

## 6. Posting

Now let's make a controller to make our first post.

    $ script/generate controller Tweets new create

Now we'll set up <code>app/controllers/tweets\_controller\_.rb</code>:

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

...and <code>app/views/tweets/new.html.erb</code>:

    <p><% form_tag :action => 'create' do %>
    What's happening? <%= text_field_tag :tweet %>
    <% end -%></p>

### Authenticating Your Actions

Set up your <code>app/controllers/application\_controller.rb</code> so any controller can be authenticated:

    class ApplicationController < ActionController::Base
      helper :all
      protect_from_forgery

      rescue_from OAuth::Unauthorized, :with => :force_login
      rescue_from Twitter::Unauthorized, :with => :force_login
      rescue_from ActionController::InvalidAuthenticityToken, :with => :force_login

      private
        def oauth
          @oauth ||= Twitter::OAuth.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'])
        end

        def twitter_client
          oauth.authorize_from_access(session[:access_key], session[:access_secret])
          Twitter::Base.new(oauth)
        end

        def force_login(exception)
          reset_session
          flash[:error] = 'Credentials expired -- please sign in again.'
          redirect_to :controller => :sessions, :action => :new
        end

        def verify_login
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

...and since authentication requires sessions, also create <code>app/controllers/sessions\_controller.rb</code>:

    class SessionsController < ApplicationController
      def new
      end

      def create
        oauth.set_callback_url url_for(:controller => :sessions, :action => :write)

        session[:rtoken_key]  = oauth.request_token.token
        session[:rtoken_secret] = oauth.request_token.secret

        auth_redirect = oauth.request_token.authorize_url

        if !auth_redirect.match(/^http/)
          # work around bug in Twitter gem 0.9.8
          # see http://github.com/jnunemaker/twitter/issuesearch?state=open&q=http#issue/46
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
        session[:access_key] = oauth.access_token.token
        session[:access_secret] = oauth.access_token.secret

        sign_in(user)
        redirect_back_or root_path
      end
    end

...and create a view in <code>app/views/sessions/new.html.erb</code>:

    <p>You'll need to sign in using Twitter</p>
    <% form_tag :controller => :sessions, :action => :create do %>
      <p><%= submit_tag "Sign In" %></p>
    <% end -%>

...and finally, set up <code>config/routes.rb</code> to route tweet actions: 

    ActionController::Routing::Routes.draw do |map|
      map.root :controller => :tweets

      map.connect ':controller/:action/:id'
      map.connect ':controller/:action/:id.:format'
    end


To see how it all ties together, consider what happens if you go to [/tweets/new](http://0.0.0.0:3000/tweets/new) for the first time:

- TweetsController calls the <code>verify\_login</code> filter.
- <code>verify\_login</code> can't verify the login, so it redirects to <code>/sessions/new</code> to create a new session.
- The <code>SessionsController#new</code> page tells the user they need to log in via Twitter.
- The user clicks "Sign In", which calls <code>SessionsController#create</code>.
- <code>SessionsController#create</code> gets a new Request Token from Twitter, then redirects the browser to Twitter so the user can authorize the request.
- When the user authorizes the request, Twitter redirects the browser back to <code>/sessions/write</code>, which stores the Access Token and redirects to the page that started this process

### Doing Things While Authenticated.

Now let's look at what happens if you post from [/tweets/new](http://0.0.0.0:3000/tweets/new) after the first time:

- TweetsController calls the <code>verify\_login</code> filter.
- <code>verify\_login</code> returns without incident.
- <code>TweetsController#create</code> calls twitter\_client, which re-authorizes the connection using the (still valid) Access Token, then returns the authorized Twitter object.

Similarly, any action you need to do while logged in via OAuth should be done by calling twitter_client:

    tweet = twitter_client.update(params[:tweet])

We'll use the same trick for other api calls. For example, we could see who we follow:

    twitter_client.friend_ids

In fact, let's add a timeline method to the Users controller:

    def timeline
      @timeline = twitter_client.friends_timeline
    end

with <code>app/views/users/timeline.html.erb</code> to match:

    Timeline for @<%= session[:screen_name] %>:
    <table>
      <tr><td>Who</td><td>What</td></tr>
      <% @timeline.each do |tweet| %><tr>
        <td>@<a href="http://www.twitter.com/<%= tweet['user']['screen_name'] %>"><%= tweet['user']['screen_name'] %></a></td>
        <td><%= tweet['text'] %></td>
      </tr><% end %>
    </table>

This gives us the same timeline traffic we'd be seeing on twitter.com, but loaded through our Ruby app where we can manipulate it.

### Other Things The App Could Do While the User is Logged In

Once your app is authenticated, you can use the Twitter gem to call most of the Twitter APIs. This lets you:

- Search in a number of ways, using Twitter::Search
- Watch Trends, using Twitter::Trends
- Work with place-based updates, using Twitter::Geo and Twitter::LocalTrends

For more info on the available APIs, see the [Twitter gem's documentation](http://rdoc.info/projects/jnunemaker/twitter)

## 7. Using Apigee

[Apigee](http://www.apigee.com) is a third-party service that give you API testing, debugging and analytics for your API use.  By using Apigee, you also get to bypass Twitter's [rate limits](http://apiwiki.twitter.com/Rate-limiting), which makes your app more scalable.

The new Apigee Heroku plugin makes it really easy to hook your app in to Apigee. For now, that gets you Apigee's higher rate limits, and Heroku has announced a (forthcoming) integrated analytics dashboard which will let you easily analyze and debug your app's api use.

To set it up, start by adding the free version of Apigee:

    $ heroku addons:add apigee:free

This will add an APIGEE\_TWITTER\_API\_ENDPOINT variable to your running app. Apigee is implemented as a proxy in front of Twitter (and other REST APIs), so you'll use the APIGEE\_TWITTER\_API\_ENDPOINT as the place to make Twitter API calls. Modify <code>ApplicationsController#oauth</code> to do so:

    def oauth
      if !ENV['APIGEE_TWITTER_API_ENDPOINT'].nil?
        api_endpoint = 'http://' + ENV['APIGEE_TWITTER_API_ENDPOINT']
      else
        api_endpoint = nil
      end

      @oauth ||= Twitter::OAuth.new(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'], :api_endpoint => ENV['APIGEE_TWITTER_API_ENDPOINT'])
    end

The Apigee plugin will automatically populate <code>APIGEE\_TWITTER\_API\_ENDPOINT</code> on Heroku. To use it in your local development machine you'll need to retrieve the environment variable locally.

See your app's runtime environment variables:

    $ heroku config

..and look for the <code>APIGEE\_TWITTER\_API\_ENDPOINT</code> variable and set it locally.

    export APIGEE_TWITTER_API_ENDPOINT=twitter-api.your-apps-unique-url.apigee.com

(Replace <code>twitter-api.your-apps-unique-url.apigee.com</code> with what <code>config</config> reports.)

## 8. Notes and Resources

### Catching a Fail Whale, and Other Exceptions

Because Twitter sometimes gets overloaded by current events, the Twitter gem uses a number of exceptions to handle problems. Production apps should catch exceptions such as <code>Twitter::Unavailable</code> and <code>Twitter::RateLimitExceeded</code>.

### Logging out, and Revoking Access

- In this example app, <code>SessionsController#destroy</code> is a public method, so visiting <code>/sessions/destroy</code> will sign out your user. You may want to put some checks around that.

- When a user authorizes your app, it will be added to their list of authorized apps on [Twitter's Connections page](https://twitter.com/settings/connections). The user can de-authorize your app by removing it from that list.

### Other APIs

- The Twitter gem does not provide any support for the [@anywhere](http://dev.twitter.com/anywhere/) API, because @anywhere is implemented using client-side JavaScript.

- Twitter's [Streaming API](http://dev.twitter.com/pages/streaming_api) isn't yet compatible with Heroku, since the API requires a long-lived socket to which Twitter can write back.

### Local User Data

This demo app did not store any user data locally, and used cookie-based sessions. This may not be what you need:

- If you use ActiveRecord based sessions, or store user data along with the login info, then you should make sure your Heroku account has enough database space and performance to support your application. The default 5MB should be enough for developer use, but a successful app's load and user base will exceed that.

- This application uses Twitter for authentication and authorization, but after login the authorization is only checked when the user makes a request of Twitter. If your application includes actions that don't talk to Twitter then you need to handle situations where the user's Twitter authorization has changed but your application hasn't received that information.

### More resources

- For more information about OAuth, see the [About OAuth](http://oauth.net/about/) page, and Eran Hammer-Lahav's [Explaining OAuth](http://hueniverse.com/oauth/)
- [John Nunemaker](http://railstips.org/) has a richer and more fully-featured [demo app](http://github.com/jnunemaker/twitter-app).
- Be sure to follow @[twitterapi](http://twitter.com/twitterapi) for updates on the APIs, and watch the [Twitter Status](http://status.twitter.com/) page for current API service status.
- The Twitter gem isn't the only gem for Twitter. Some others to consider include:
  - [Grackle](http://github.com/hayesdavis/grackle) is a very light wrapper around the REST API calls, which makes it a bit less polished but also more resilient to underlying API changes. Maintainer [Hayes Davis] also uses it as a [client for Gowalla](http://hayesdavis.net/2010/06/16/grackwalla-talking-to-the-gowalla-api-using-grackle/).
  - [twitter4r](http://twitter4r.rubyforge.org/) is another gem providing Ruby-style wrapper around the REST api.
  - [twitter-auth](http://github.com/mbleigh/twitter-auth) provides a generator to create a login system.
  - [authlogic_oauth](http://github.com/jrallison/authlogic_oauth) is an extension of the [Authlogic](http://rdoc.info/projects/binarylogic/authlogic) gem, providing OAuth support.
