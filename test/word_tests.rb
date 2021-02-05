ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../word.rb"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  # the session[:word] is "APPLE" (the only word in the .yaml file loaded from
  # the test directory)

  def test_home
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to Guess the Word game"
  end

  def test_word
    get "/"
    get "/word"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Your word has"
    assert_includes last_response.body, "Letters to pick from"
    assert_includes last_response.body, "Letters already picked"
    assert_includes load_words.map(&:upcase), session[:word]
  end

  def test_new
    get "/new"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Your word has"
    assert_includes load_words.map(&:upcase), session[:word]
  end

  def test_pick_letter
    get "/"
    get "/word"
    post "/choose_letter", letter: "P"

    # To access the form data from the request:
    # First need to access the request:
    # puts last_request
    # => #<Rack::Request:0x00007fb36aa83c00>

    # last_request.env returns a hash
    # with all the info about the request. Within this env hash is an item
    # "rack.request.form_hash"=>{"letter"=>"P"}, where the string
    # "rack.request.form_hash" is a key with a value of a hash that contains the
    # data submitted in the form
    # puts last_request.env["rack.request.form_hash"]
    # => {"letter"=>"P"}
    # shorter alternative:
    # puts last_request.params
    # => {"letter"=>"P"}

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "APPLE", session[:word]
    assert_includes session[:placeholder].values, " P "
    assert_includes session[:picked], "P"

    get last_response["Location"]

    assert_equal 200, last_response.status

    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Your word has"
  end

  def test_end
    get "/end"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Would you like to play again"
  end

  def test_guessing_word
    get "/"
    get "/word"
    post "/choose_letter", letter: "A"
    post "/choose_letter", letter: "P"
    post "/choose_letter", letter: "P"
    post "/choose_letter", letter: "L"
    post "/choose_letter", letter: "E"

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:message], "great job"

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Would you like to play again"
  end

  def test_out_of_points
    get "/"
    get "/word"
    post "/choose_letter", letter: "B"
    post "/choose_letter", letter: "C"
    post "/choose_letter", letter: "D"
    post "/choose_letter", letter: "F"
    post "/choose_letter", letter: "G"
    post "/choose_letter", letter: "H"
    post "/choose_letter", letter: "I"
    post "/choose_letter", letter: "J"
    post "/choose_letter", letter: "K"
    post "/choose_letter", letter: "M"


    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes session[:message], "the word was"

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Would you like to play again"
  end

  def test_finish
    get "/finish"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Goodbye"
  end
end