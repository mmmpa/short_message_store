get '/' do
  slim :index
end

get '/messages/index' do
  if from_id
    Message.list_after(from_id).to_json
  else
    Message.all.to_json
  end
end

post '/messages/new' do
  Message.new(message_params).save!
end

delete '/messages/:id' do |id|
  Message.destroy(id)
  {id: id}.to_json
end

get '/css/def.css' do
  content_type 'text/css', charset: 'utf-8'
  sass :def
end

get '/js/app.js' do
  content_type 'text/javascript', charset: 'utf-8'
  coffee :react
end

private

def symbolize_params
  @normalized ||= params.deep_symbolize_keys!
end

def message_params
  symbolize_params.slice(:message)
end

def from_id
  symbolize_params[:from]
end