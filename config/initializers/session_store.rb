# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_twitteroku_session',
  :secret      => '7d89e200cf4e8450ddb9e064c042eb59697ccbcc934ec8e41455841b5d2d07c5e0446565aca8a8d0019eff4494c6265a74b82f42f2b3b4836b671f9881df0ec4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
