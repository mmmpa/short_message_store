set :views, Common::ROOT + 'app/views'
enable :sessions

get '/' do
  slim :index
end

private

def symbolize_params
  @normalized ||= params.deep_symbolize_keys!
end
