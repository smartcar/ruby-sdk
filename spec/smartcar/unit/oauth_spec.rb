RSpec.describe Smartcar::Oauth do
  subject { Smartcar::Oauth }
  let(:obj) { double("dummy object for client") }

  before do
    allow(subject).to receive(:get_config).with('REDIRECT_URI').and_return("test_url")
    allow(subject).to receive_message_chain(:client, :auth_code).and_return(obj)
  end

  context 'authorization_url' do
    it 'should call authorize_url from client.authcode' do
      expect(obj).to receive(:authorize_url).with({
        redirect_uri: "test_url",
        approval_prompt: Smartcar::AUTO,
        mode: Smartcar::TEST,
        response_type: Smartcar::CODE,
        scope: "testing"
      }).and_return("result")
      expect(subject.authorization_url(test_mode: true, scope: ["testing"])).to eq "result"
    end
  end
  # def refresh_token(token_hash)
  #   token_object = OAuth2::AccessToken.from_hash(client, token_hash)
  #   token_object.refresh!
  #   token_object.to_hash
  # end

  context 'get_token' do
    it 'should call get_token from client.authcode' do
      expect(obj).to receive(:get_token).with("auth_code", {redirect_uri: "test_url"}).and_return(double("obj", to_hash: {result: "result"}))
      expect(subject.get_token("auth_code")).to eq({result: "result"})
    end
  end

  context 'refresh_token' do
    it 'should create new OAuth2::AccessToken object, refresh and return new hash' do
      token_hash = {token: "token"}
      double_object = double("obj")
      allow(subject).to receive_message_chain(:client).and_return(obj)
      expect(OAuth2::AccessToken).to receive(:from_hash).with(obj,token_hash).and_return(double_object)
      expect(double_object).to receive(:refresh!).and_return(double_object)
      expect(double_object).to receive(:to_hash)
      subject.refresh_token(token_hash)
    end
  end

  context 'client' do
    before do
      allow(subject).to receive(:client).and_call_original
    end
    it 'should create OAuth2::Client object' do
      expect(subject).to receive(:get_config).twice
      expect(OAuth2::Client).to receive(:new)
      subject.send(:client)
    end
  end

  describe 'get_config' do
    before do
      allow(subject).to receive(:get_config).and_call_original
    end
    context 'If the config is present' do
      before do
        stub_const("ENV", {'test' => "result"})
      end
      it 'should get the requested config' do
        expect(subject.send(:get_config,"test")).to eq("result")
      end
    end
    context 'If the config is not present' do
      before do
        stub_const("ENV", {})
      end
      it 'should get raise ConfigNotFound' do
        expect{subject.send(:get_config,"test")}.to raise_error(Smartcar::ConfigNotFound,"Environment variable test not found !" )
      end
    end
  end
end
