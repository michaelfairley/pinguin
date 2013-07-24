require 'spec_helper'
require 'timeout'
require 'support/http_server'
require 'pinguin/checks/http'

class Pinguin
  module Checks
    describe HTTP do
      it_behaves_like "a check", "http"

      before(:all) { @server = HTTPServer.run }
      after(:all) { @server.stop }

      around(:each) {|example| Timeout::timeout(1, SpecTimeoutError) { example.run } }

      subject(:check) { HTTP.new('url' => url(200)) }

      def url(code, params={})
        query_string = "?" + params.map{|k,v| "#{k}=#{v}" }.join("&")
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

      describe "read_timeout" do
        it "fails if the response takes longer than the timeout" do
          HTTP.new('url' => url(200, :sleep => 1), 'read_timeout' => 0.01).check.should_not be_successful
        end

        it "defaults to 10" do
          check.read_timeout.should == 10
        end
      end

      describe "connect_timeout" do
        it "fails if the response takes longer than the timeout" do
          HTTP.new('url' => url(200), 'connect_timeout' => 0.01).check.should be_successful
          HTTP.new('url' => "http://192.0.2.1/", 'connect_timeout' => 0.01).check.should_not be_successful
        end

        it "defaults to 10" do
          check.connect_timeout.should == 10
        end
      end

      describe "request headers"
      describe "response headers"
      describe "SSL verification"
      describe "HTTP verb"

      describe "bad hosts" do
        it "fails if the connection is refused" do
          # find unused port...
          HTTP.new('url' => "http://localhost:19848/").check.should_not be_successful
        end

        it "fails if the hostname cannot be resolved" do
          HTTP.new('url' => "http://invalid.invalid/").check.should_not be_successful
        end
      end
    end
  end
end
