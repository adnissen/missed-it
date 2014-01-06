require 'sinatra'
require 'torrent_api'
require 'httpclient'
require 'json'


def getShows 
  t = Time.now
  startDate = t.year.to_s
  startDate += sprintf '%02d', t.month.to_s
  startDate += sprintf '%02d', (t.day - 1).to_s
  # our http client
  http = HTTPClient.new
  JSON.parse(http.get("http://api.trakt.tv/calendar/shows.json/83b415e4b1cc046964e22fa1529a5ac8/" + startDate +"/2").content)
end 

def getTorrents (showList)
  # our torrent object
  t = TorrentApi.new	
  foundAry = Array.new
  showList[0]["episodes"].each_with_index do |item, index|
    puts index
    puts showList[0]["episodes"][index]["show"]["title"]
    title = showList[0]["episodes"][index]["show"]["title"]
    season = sprintf '%02d', showList[0]["episodes"][index]["episode"]["season"]
    number = sprintf '%02d', showList[0]["episodes"][index]["episode"]["number"]
    t.search_term = title + " s" + season + "e" + number + " 720p"
    r = Array.new
    if title != ""
    r = t.search
    end
    unless r == []
      checkString = "S" + season + "E" + number
      if r[0].name.include? checkString
        # if we make it here, we know there's a link
        # so we can add both the title and the link to our json or array or w/e
        magnet_link = URI.escape(r[0].magnet_link)
        size = r[0].size
        name = r[0].name
        puts magnet_link
        showInfo = {title: title, name: name, magnet_link: magnet_link, size: size, season: season, number: number}
        foundAry.push(showInfo)
      end
    else
      t.search_term = title + " s" + season + "e" + number + " 480p"
      r = Array.new
      if title != ""
      r = t.search
        unless r == []
          checkString = "S" + season + "E" + number
          if r[0].name.include? checkString
            # if we make it here, we know there's a link
            # so we can add both the title and the link to our json or array or w/e
            magnet_link = URI.escape(r[0].magnet_link)
            size = r[0].size
            name = r[0].name
            puts magnet_link
            showInfo = {title: title, name: name, magnet_link: magnet_link, size: size, season: season, number: number}
            foundAry.push(showInfo)
          end
        end
      end
    end
  end
  foundAry
end

configure do
  # the array with all the shows found
  set :erb, :escape_html => true
  shows = Array.new
  showList = getShows
  shows = getTorrents(showList) 
  set :showList, showList
  set :shows, shows
  set :torrentLastUpdated, Time.now
  set :showListLastUpdated, Time.now
end

after do
  if Time.now - settings.torrentLastUpdated > 5 * 60
    settings.torrentLastUpdated = Time.now
    puts "Updating Torrents"
    newShows = getTorrents(settings.showList)
    settings.shows = newShows
  end

  if Time.now - settings.showListLastUpdated > 60 * 60
    settings.showListLastUpdated = Time.now
    puts "Updating Show List"
    newList = getShows
    settings.showList = newList
  end
end

get '/' do
  erb :index
end