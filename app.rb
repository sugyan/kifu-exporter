require 'sinatra/base'
require 'jkf'
require 'nokogiri'
require 'open-uri'

class App < Sinatra::Base

  get '/' do
    erb :index
  end

  get '/kifu' do
    doc = Nokogiri::HTML(open(params['url']))
    data = JSON.parse(doc.search("[@data-react-class='games/Show']").attribute('data-react-props'))
    game = data['gameHash']

    lines = []
    lines << "V2.2"
    lines << "N+#{game['sente']}"
    lines << "N-#{game['gote']}"
    lines << "PI"
    lines << "+"
    times = [600, 600]
    game['moves'].each.with_index do |move, idx|
      lines << move['m']
      lines << "T#{times[idx % 2] - move['t']}"
      times[idx % 2] = move['t']
    end
    csa = lines.join("\n")
    out = case params['format']
    when 'kif'
      jkf = Jkf.parse(csa)
      jkf['moves'].each do |move|
        move.delete('time')
      end
      Jkf::Converter::Kif.new.convert(jkf)
    when 'csa'
      csa
    end

    content_type 'text/plain'
    out
  end

  run! if app_file == $0
end
