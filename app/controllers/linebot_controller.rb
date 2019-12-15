class LinebotController < ApplicationController

	require "line/bot"  # gem "line-bot-api"

	# callbackアクションのCSRFトークン認証を無効
	protect_from_forgery :except => [:callback]

	def client
		@client ||= Line::Bot::Client.new { |config|
			config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
			config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
		}
	end

    def search id
        [
            { "id" => "",  "val" => {"a" => "屋内", "b" => "屋外"} },
            { "id" => "a",  "val" => {"c" => "音楽", "d" => "運動"} }, #a:屋内
            { "id" => "c",  "val" => {"e" => "歌", "f" => "楽器"} }, #c:音楽
            { "id" => "e",  "val" => "https://karaokeclub.jp/shop/%E3%82%AB%E3%83%A9%E3%82%AA%E3%82%B1club-dam-resort-%E6%9D%BE%E6%B1%9F%E9%A7%85%E5%89%8D%E9%80%9A%E3%82%8A%E5%BA%97/" }, #e:歌
            { "id" => "f",  "val" => "https://gakkiya-navi.com/shimane/matsue/320003/" }, #f:楽器
            { "id" => "d",  "val" => "https://t2style.jp/" }, #d:運動
            { "id" => "b",  "val" => "https://jmty.jp/shimane/com-kw-%E7%99%BB%E5%B1%B1" } #b:屋外
        ].find{|e| e["id"] == id }
    end


	def callback
		body = request.body.read

		signature = request.env["HTTP_X_LINE_SIGNATURE"]
		unless client.validate_signature(body, signature)
			error 400 do "Bad Request" end
		end
	
		events = client.parse_events_from(body)

		events.each { |event|
			case event
			when Line::Bot::Event::Message
				case event.type
				when Line::Bot::Event::MessageType::Text
				    
				    if event.message["text"] =~ /start/ then
				        value = search("")["val"]
				    	message = {
				       		type: "text",
				    		text: value["a"] + "ですか？" + value["b"] + "ですか？"
				            # text: "hoge"
					    }
			        	client.reply_message(event["replyToken"], message)
			        end

				when Line::Bot::Event::MessageType::Location
					message = {
						type: "location",
						title: "あなたはここにいますか？",
						address: event.message["address"],
						latitude: event.message["latitude"],
						longitude: event.message["longitude"]
					}
					client.reply_message(event["replyToken"], message)
				end
			end
		}

		head :ok
	end
end
