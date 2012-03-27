require 'spec_helper'

describe "UrlRetriever#retrieve_content_at" do
  it "should fetch URIs with query strings" do
    stubbed_response = stub(:code => '200')
    stubbed_response.should_receive(:body).and_return('mock body')
    Net::HTTP.stub!(:new).and_return(stub('Net::HTTP stub', :[] => nil, :code => '200', :read_timeout= => nil, :open_timeout= => nil, :start => stubbed_response).as_null_object)
    Net::HTTP::Get.should_receive(:new).with('/path.html?parameter=value').and_return(stub('HTTP::Get stub').as_null_object)
    UrlRetriever.retrieve_content_at('http://host/path.html?parameter=value').should == "mock body"
  end

  it "should try BASIC AUTH first if credentials are provided" do
    stubbed_response = stub(:code => '200')
    stubbed_response.should_receive(:[]).with('www-authenticate').and_return(nil)
    stubbed_response.should_receive(:body).and_return('mock body')
    Net::HTTP.stub!(:new).and_return(stub('Net::HTTP stub', :[] => nil, :code => '200', :read_timeout= => nil, :open_timeout= => nil, :start => stubbed_response).as_null_object)
    http_get = stub('HTTP::Get stub')
    Net::HTTP::Get.should_receive(:new).with('/path.html?parameter=value').and_return(http_get)
    http_get.should_receive(:basic_auth).with('user', 'pass')
    UrlRetriever.retrieve_content_at('http://host/path.html?parameter=value', 'user', 'pass')
  end

  describe "#http" do
    it "should respect the uri's scheme" do
      http1 = UrlRetriever.send(:http, URI.parse("http://example.com"))
      http1.use_ssl?.should be_false

      http2 = UrlRetriever.send(:http, URI.parse("https://example.com"))
      http2.use_ssl?.should be_true
    end
  end
end
