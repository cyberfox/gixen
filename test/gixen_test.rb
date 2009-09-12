#!/usr/bin/env ruby

require 'rubygems'

require 'gixen'
require 'fake_web'
require 'shoulda'

class GixenTest < Test::Unit::TestCase
  @@prefix = Gixen::CORE_GIXEN_URL + "?username=test&password=test&notags=1"
  @@bad_prefix = Gixen::CORE_GIXEN_URL + "?username=test&password=incorrect&notags=1"
  BAD_LOGIN = "ERROR (101): COULD NOT LOG IN"
  FakeWeb.allow_net_connect = false

  def mock_bad_password(body, options)
    mock_url = "#{@@bad_prefix}&#{options.to_param}"
    FakeWeb.register_uri(:get, mock_url, :body => body)
  end

  context "Using a bad password to talk to Gixen" do
    setup do
      @gixen = Gixen.new('test', 'incorrect')
      mock_bad_password(BAD_LOGIN, :listsnipesmain => 1)
    end

    should "throw an exception with code 101" do
      thrown = assert_raise Gixen::GixenError do
        result = @gixen.main_snipes
      end
      assert_equal 101, thrown.code
    end
  end
end
