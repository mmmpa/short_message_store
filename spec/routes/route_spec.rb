describe 'Route' do
  def app
    Sinatra::Application
  end

  context 'when get /' do
    before :each do
      get '/'
    end

    it { expect(last_response).to be_ok }
    skip { expect(last_response.body).to have_tag('h1', text: 'slim') }
  end
end