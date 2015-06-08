require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'open-uri'
require 'openssl'
require 'json'
require 'youtube_it'

API_KEY = ENV['YOUTUBE_API_KEY']
USER_NAME = ENV['YOUTUBE_USER_NAME']
PASSWORD = ENV['YOUTUBE_USER_PASSWORD']
PLAYLIST_NAME = ENV['YOUTUBE_PLAYLIST_NAME']

get '/' do
  slim :index
end

get '/search' do
  keyword = @params[:keyword]
  redirect '/' if keyword.empty?

  @videos = searchVideos(keyword)
  slim :search
end

get '/add' do
  redirect '/'
end

post '/add' do
  video_id = @params["video_id"]
  p video_id
  client = YouTubeIt::Client.new(:username => USER_NAME, :password => PASSWORD, :dev_key => API_KEY)
  target_playlist = client.playlists.find { |playlist| playlist.title == PLAYLIST_NAME }
  target_id = target_playlist.playlist_id
  client.add_video_to_playlist(target_id, video_id)

  redirect '/'
end

def searchVideos(keyword)
  endpoint = 'https://www.googleapis.com/youtube/v3/search'
  uri = URI.parse(endpoint)
  search_keyword = URI.escape(keyword.gsub(' ', '+'))
  query_hash = {
    "key" => API_KEY,
    "q" => search_keyword,
    "part" => 'snippet',
    "maxResults" => '10',
    "type" => 'video'
  }
  query = query_hash.map{|k,v| "#{k}=#{v}"}.join('&')
  uri.query = query

  res = open(uri.to_s, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
  code, message = res.status

  videos = []
  if code == '200'
    json = JSON.parse(res.read)
    json['items'].each do |item|
      id = item['id']['videoId']
      snipped = item['snippet']

      endpoint = 'https://www.googleapis.com/youtube/v3/videos'
      uri = URI.parse(endpoint)
      query_hash = {
        "key" => API_KEY,
        "id" => id,
        "part" => 'snippet,contentDetails,statistics,status'
      }
      query = query_hash.map{|k,v| "#{k}=#{v}"}.join('&')
      uri.query = query
      res = open(uri.to_s, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
      code, message = res.status
      if code == '200'
        json = JSON.parse(res.read)
        duration = json['items'].first['contentDetails']['duration']
        /(\d+)H/ =~ duration
        hours = $1
        /(\d+)M/ =~ duration
        minutes = $1

        length = duration.gsub(/^PT/, '').gsub('H', '時間').gsub('M', '分').gsub('S', '秒')
      end

      ## 10分以上ある動画は追加させない
      next if hours || minutes.to_i > 10

      video = {
        id: id,
        title: snipped['title'],
        length: length,
        description: snipped['description'],
        thumbnail_url: snipped['thumbnails']['high']['url']
      }
      videos << video
    end
  else
    puts "OMG!! #{code} #{message}"
  end

  return videos
end
