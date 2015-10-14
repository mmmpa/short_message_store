get '/' do
  slim :index
end

get '/messages/index' do

end

post '/messages/new' do
  Message.new(message_params).save!
end

delete '/messages/:id' do |id|
  Message.destroy(id)
end

get '/css/def.css' do
  content_type 'text/css', charset: 'utf-8'
  sass :def
end

private

def symbolize_params
  @normalized ||= params.deep_symbolize_keys!
end

def message_params
  symbolize_params.slice(:message)
end