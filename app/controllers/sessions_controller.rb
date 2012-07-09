#This is currently not used.  Maybe add this functionality later
#
# class SessionsController < ApplicationController
#   skip_before_filter :register

#   def new
#   end

#   def create
#     user = params[:name]
#     email = params[:email]
#     if user and email
#       #<%= render %> some javascript to send ajax/JSON request or send one from here
#       #to register the player with P45 Server
#     #   session[:user_id] = user.id
#     #   redirect_to admin_url
#     else
#       redirect_to register_url, alert: "Invalid user/password combination"
#     end
#   end

#   def destroy
#     # session[:user_id] = nil
#     # redirect_to store_url, notice: "Logged out"
#   end

# end
