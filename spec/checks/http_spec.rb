require 'spec_helper'
require 'support/http_server'
require 'pinguin/checks/http'

module Pinguin
  module Checks
    describe HTTP do
      before(:all) { @server = HTTPServer.run }
      after(:all) { @server.stop }

      def url(code, params={})
        query_string = params.empty? ? '' : "?" + params.map{|k,v| "#{k}=#{v}" }.join("&")
        "http://localhost:#{@server.port}/#{code}#{query_string}"
      end

      describe "url" do
        it "is required" do
          expect do
            HTTP.new
          end.to raise_error(KeyError)
        end
      end

      describe "response code" do
        it "passes if the response code matches" do
          [200, 404, 503].each do |code|
            HTTP.new('url' => url(code), 'response_code' => code).check.should be_successful
          end
        end

        it "fails if the response code doesn't match" do
          [200, 404, 503, 200].each_cons(2) do |code, wrong|
            HTTP.new('url' => url(wrong), 'response_code' => code).check.should_not be_successful
          end
        end

        it "matches fuzzily with x's" do
          HTTP.new('url' => url(204), 'response_code' => "2xx").check.should be_successful
          HTTP.new('url' => url(404), 'response_code' => "2xx").check.should_not be_successful
          HTTP.new('url' => url(204), 'response_code' => "2x0").check.should_not be_successful
        end

        it "matches 2xx by default" do
          HTTP.new('url' => url(200)).check.should be_successful
          HTTP.new('url' => url(204)).check.should be_successful
          HTTP.new('url' => url(404)).check.should_not be_successful
          HTTP.new('url' => url(500)).check.should_not be_successful
        end
      end

      describe "follow redirects" do
        it "follows redirects when true" do
          HTTP.new('url' => url(302), 'follow_redirects' => true).check.should be_successful
          HTTP.new('url' => url(302, :to => 500), 'follow_redirects' => true).check.should_not be_successful
        end

        it "doesn't follow redirects if the response matches the conditions" do
          HTTP.new('url' => url(302, :to => 500), 'response_code' => 302, 'follow_redirects' => true).check.should be_successful
        end

        it "doesn't follow redirects if it's off" do
          HTTP.new('url' => url(302), 'follow_redirects' => false).check.should_not be_successful
        end

        it "is on by default" do
          HTTP.new('url' => url(302)).check.should be_successful
        end

        describe "redirect limit" do
          it "stops following redirects when the limit is passed" do
            HTTP.new('url' => url(302, :times => 10), 'redirect_limit' => 10).check.should be_successful
            HTTP.new('url' => url(302, :times => 10), 'redirect_limit' => 9).check.should_not be_successful
          end

          it "5 by default" do
            HTTP.new('url' => url(302, :times => 5)).check.should be_successful
            HTTP.new('url' => url(302, :times => 6)).check.should_not be_successful
          end
        end
      end

      describe "matching content"
      describe "timeouts"
      describe "request headers"
      describe "response headers"
      describe "SSL verification"
      describe "HTTP verb"
      describe "bad hosts"
    end
  end
end
