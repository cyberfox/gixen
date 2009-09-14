#!/usr/bin/env ruby

require 'rubygems'

require 'gixen'
require 'fake_web'
require 'shoulda'
require 'to_query'

class GixenTest < Test::Unit::TestCase
  @@prefix = Gixen::CORE_GIXEN_URL + "?username=test&password=test&notags=1"
  @@bad_prefix = Gixen::CORE_GIXEN_URL + "?username=test&password=incorrect&notags=1"
  BAD_LOGIN = "ERROR (101): COULD NOT LOG IN\r\n"
  LISTINGS = <<EOMOCK
<br />|#!#|123456789|#!#|1252807311|#!#|98.76|#!#|N|#!#||#!#|A Simple Testing Auction|#!#|0|#!#|1|#!#|6
<br />|#!#|987654321|#!#|1252806079|#!#|12.34|#!#|S|#!#|Skipped|#!#|A Skipped Tested Auction|#!#|0|#!#|1|#!#|6
<br />|#!#|314159265|#!#|1252807311|#!#|98.76|#!#|D|#!#|Completed|#!#|A Completed Test Auction|#!#|0|#!#|1|#!#|6
EOMOCK
  BAD_LISTINGS = LISTINGS.collect{|x| "#{x.strip}|#!#|NewField|#!#|OtherNewField"}.join("\r\n")
  MAIN_LISTINGS = LISTINGS + "\r\n<br />OK MAIN LISTED\r\n"
  MIRROR_LISTINGS = LISTINGS + "\r\n<br />OK MIRROR LISTED\r\n"

  FakeWeb.allow_net_connect = false

  def mock(body, options)
    mock_url = "#{@@prefix}&#{options.to_query}"
    FakeWeb.register_uri(:get, mock_url, :body => body)
  end

  def mock_bad_password(body, options)
    mock_url = "#{@@bad_prefix}&#{options.to_query}"
    FakeWeb.register_uri(:get, mock_url, :body => body)
  end

  def teardown
    FakeWeb.clean_registry
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
      assert_equal '101 could_not_log_in - COULD NOT LOG IN', thrown.to_s
    end
  end

  context "Receiving an invalid response for a snipe set" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock('', :itemid => '123456789', :maxbid => '98.76')
    end

    should "fail" do
      result = @gixen.snipe('123456789', '98.76')
      assert_equal false, result
    end
  end

  context "Adding a snipe" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock("OK 123456789 ADDED\r\n", :itemid => '123456789', :maxbid => '98.76')
    end

    should "succeed" do
      result = @gixen.snipe('123456789', '98.76')
      assert_equal true, result
    end
  end

  context "Deleting a snipe" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock("OK 123456789 DELETED\r\n", :ditemid => '123456789')
    end

    should "succeed" do
      result = @gixen.unsnipe('123456789')
      assert_equal true, result
    end
  end

  context "Getting the list of snipes on the main server" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock(BAD_LISTINGS, :listsnipesmain => 1)
    end

    should "still return 3 results when weird things happen" do
      result = @gixen.main_snipes
      assert_equal 3, result.length
    end

    should "put unexpected entries into hash entries named for their column number" do
      result = @gixen.main_snipes
      assert_equal 'NewField', result.first[10]
      assert_equal 'OtherNewField', result.first[11]
    end
  end

  context "Getting the list of snipes on the main server" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock(MAIN_LISTINGS, :listsnipesmain => 1)
    end

    should "return 3 results" do
      result = @gixen.main_snipes
      assert_equal 3, result.length
    end

    should "return a first result with itemid 123456789" do
      result = @gixen.main_snipes
      assert_equal '123456789', result.first[:itemid]
    end

    should "return a last result with itemid 314159265" do
      result = @gixen.main_snipes
      assert_equal '314159265', result.last[:itemid]
    end
  end

  context "Getting the list of snipes on the mirror server" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock(MIRROR_LISTINGS, :listsnipesmirror => 1)
    end

    should "return 3 results" do
      result = @gixen.mirror_snipes
      assert_equal 3, result.length
    end

    should "return a first result with itemid 123456789" do
      result = @gixen.mirror_snipes
      assert_equal '123456789', result.first[:itemid]
    end

    should "return a last result with itemid 314159265" do
      result = @gixen.mirror_snipes
      assert_equal '314159265', result.last[:itemid]
    end
  end

  context "Purging the list of items that are ended" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock("OK COMPLETEDPURGED\r\n", :purgecompleted => 1)
    end

    should "succeed" do
      result = @gixen.purge
      assert_equal true, result
    end
  end

  context "Getting the list of snipes on both servers" do
    setup do
      @gixen = Gixen.new('test', 'test')
      mock(MAIN_LISTINGS, :listsnipesmain => 1)
      mock(MIRROR_LISTINGS, :listsnipesmirror => 1)
    end

    should "return 6 results" do
      result = @gixen.snipes
      assert_equal 6, result.length
    end

    should "return 3 results with :mirror => true" do
      result = @gixen.snipes
      assert_equal 3, result.select {|x| x[:mirror] }.length
    end

    should "return 3 results with :mirror => false" do
      result = @gixen.snipes
      assert_equal 3, result.select {|x| x[:mirror] == false }.length
    end
  end

  context "Setting a snipe while verifying the SSL certificate" do
    setup do
      @gixen = Gixen.new('test', 'test', true)
      mock("OK 123456789 ADDED\r\n", :itemid => '123456789', :maxbid => '98.76')
    end

    should "succeed" do
      result = @gixen.snipe('123456789', '98.76')
      assert_equal true, result
    end
  end
end


