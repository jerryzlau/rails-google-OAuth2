require 'google/apis/calendar_v3'
require 'google/apis/people_v1'

class AuthController < ApplicationController
  def fetch_code 
    setup_client 
    @client.update!(
      scope: "profile email #{Google::Apis::CalendarV3::AUTH_CALENDAR}",
      access_type: 'offline'
    )
    auth_uri = @client.authorization_uri.to_s
    redirect_to auth_uri 
  end 

  def oauth2callback
    setup_client 
    @client.code = params[:code]
    @client.fetch_access_token! 
    @user = User.new(access_token: @client.access_token, refresh_token: @client.refresh_token)
    
    # get the user email and name 
    response = request_email_and_name 
    if create_or_update_user(response)
      # we will render calendar instead
      # render json: @user
      setup_client(@user)
      list_calendars
    else 
      render json: @user.errors.full_messages
    end 
  end 
  
  def request_email_and_name
    # create a new instance of google service to request info 
    people = Google::Apis::PeopleV1
    people_service = people::PeopleService.new
    
    # create an options hash to tell google what info to get 
    # refer to https://developers.google.com/people/api/rest/v1/people/get 
    # to see what could be fetch from person object
    people_options = {
      request_mask_include_field: 'person.names,person.emailAddresses',
      options: {authorization: @client}
    }

    # this will return whatever is stated in the options hash 
    people_service.get_person('people/me', people_options)
  end 

  def create_or_update_user(response)
    email = response.email_addresses[0].value 
    @user = User.find_by(email: email)
    if @user.nil? 
      p first_name = response.names[0].given_name 
      @user = User.new(email: email, first_name: first_name)
    end 
    @user.access_token = @client.access_token
    @user.refresh_token ||= @client.refresh_token
    @user.save 
  end 
end
