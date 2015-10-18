get '/' do
  slim :index
end

get '/messages/index' do
  if from_id
    Message.after(from_id).map(&:to_hash).to_json
  else
    Message.all.map(&:to_hash).to_json
  end
end

post '/messages/new' do
  sleep 1
  Message.new(message_params).save!.to_json
end

put '/messages/:id' do |id|
  Message.find(id).update!(message_params).to_json
end

delete '/messages/:id' do |id|
  Message.destroy!(id)
  {id: id}.to_json
end

get '/replies/:id' do |id|
  Message.replies(id).to_json
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
  symbolize_params.slice(:message, :reply_to)
end

def from_id
  symbolize_params[:from]
end