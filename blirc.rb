require 'rubygems'
require 'sinatra'
require 'open-uri'
require 'md5'
require 'oauth'
require 'oauth/consumer'
require 'json'

enable :sessions

  $oKEY = 'VdulYO3aqGeSTy0D6dsa'
  $oPASS = 'LDl3M1r9szhymatoxNtUEM7QN20nkQif2VgSDu0w'

  $oKEY = 'gkaRVeN4gYyjAaqW2nJRgkaRVeN4gYyjAaqW2nJR'
  $oPASS = 'WmTawWjg9EVHy24IuxD7wJczwfP7zn2he3y195l8'

before do
  session[:oauth] ||= {}
  
  @consumer ||= OAuth::Consumer.new $oKEY, $oPASS, {
    :site => "http://blip.pl"
  }
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
  
  session[:user] ||= get_current_user 
  @user = session[:user]

end

helpers do
  LINK_REGEXP =  %r{https?:\/\/[^\>\<\s\"\]]+}
  TAG_REGEXP = %r{#[0-9a-zA-ZĄĆĘŃÓŁŚŹŻąćęńółśźżäëïöüÄËÏÖÜ_-]+}
  USER_REGEXP = %r{(?!\b)+(\^)(\w+)}

  def get_dashboard_since
    since = session[:last_id]
    return "" unless since
    begin
      json = @access_token.get("/dashboard/since/#{since}?include=user,recipient&limit=50").body
      updates = JSON.parse(json)
    rescue => e
      return ""
    end
    return "" unless updates.any?
    session[:last_id] = updates.first['id']
    dash_to_txt(updates.reverse)
  end
  
  def get_dashboard
    begin
      json = @access_token.get("/dashboard?include=user,recipient&limit=50").body
      updates = JSON.parse(json)
    rescue => e
      return ""
    end
    return "" unless updates.any?
    session[:last_id] = updates.first['id']
    dash_to_txt(updates.reverse)
  end

  def format_body(body)
    body.gsub(TAG_REGEXP) do |match|
      %{<span class="tag_color">#{match}</span>}
    end.gsub(LINK_REGEXP) do |match|
      %{<a href="#{match}" class="link_color">[link]</a>}
    end.gsub(USER_REGEXP) do |match| 
      %{<span class="user_color">#{match}</span>}
    end
  end

  def dash_to_txt(dash)
    out = ""
    dash.each do |update|
      out << erb(:line, :layout => false, :locals => { 
        :date => time_format(Time.parse(update["created_at"])),
        :user => update["user"]["login"],
        :recipient => update["recipient"] ? update["recipient"]["login"] : "",
        :kind => update["type"],
        :body => format_body(update["body"])
      } )
    end
    out
  end

  def get_current_user
    begin
      puts "ask for user"
      json = @access_token.get('/profile?include=background').body
      JSON.parse(json)
    rescue => e
      redirect :logout
    end
  end
  
  def time_format(time)
    time.strftime('%H:%M %d-%m-%Y')
  end

end


get "/" do
  if @access_token
    @background_url = @user["background"]["url"]
    @current_user = @user["login"]
    @body = get_dashboard
    erb :console
  else
    erb :start
  end
end

get "/refresh" do
  get_dashboard_since
end


post "/request" do
  @request_token = @consumer.get_request_token
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  redirect @request_token.authorize_url
end
 
get "/callback" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end
 
get "/logout" do
  session[:oauth] = {}
  redirect "/"
end
