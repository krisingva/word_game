require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def load_words
  if ENV["RACK_ENV"] == "test"
    path = File.expand_path("../test/words_for_tests.yaml", __FILE__)
  else
    path = File.expand_path("../word.yaml", __FILE__)
  end
  YAML.load_file(path)
end

def setup_game
  session[:word] = load_words.sample.upcase
  session[:placeholder] = create_placeholders(session[:word])
  session[:available] = ("A".."Z").to_a
  session[:picked] = []
  session[:points] = 10
end

def create_placeholders(word)
  hash = {}
  (1..(word.size)).each do |key|
    hash[key] = "_"
  end
  hash
end

def find_positions_to_change(letter)
  positions = []
  session[:word].chars.each_with_index do |char, idx|
    if char == letter
      positions << idx + 1
    end
  end
  positions
end

def change_placeholders(letter)
  positions = find_positions_to_change(letter)
  positions.each do |key|
    session[:placeholder][key] = " #{letter} "
  end
end

def word_contains_letter?(letter)
  session[:word].chars.any? {|char| char == letter }
end

def deduct_point
  session[:points] -= 1
end

def word_guessed?
  session[:placeholder].none? { |_, value| value == "_"}
end

def lost_game?
  session[:points] == 0
end

def game_lost
  session[:message] = "The game is over, the word was #{session[:word]}."
  redirect "/end"
end

def game_won
  session[:message] = "You guessed the word #{session[:word]}, great job!"
  redirect "/end"
end

get "/" do
  setup_game
  erb :home
end

get "/new" do
  setup_game
  redirect "/word"
end

get "/word" do
    @word = session[:word]
    @letter_hash = session[:placeholder]
    @alphabet = session[:available]
    @points = session[:points]
  erb :word
end

post "/choose_letter" do
  letter = params[:letter]
  change_placeholders(letter)
  session[:available].delete(letter)
  session[:picked] << letter
  deduct_point unless word_contains_letter?(letter)
  if lost_game?
    game_lost
  # if session[:points] == 0
  #   session[:message] = "The game is over, the word was #{session[:word]}."
  #   redirect "/end"
  elsif word_guessed?
    game_won
    # session[:message] = "You guessed the word #{session[:word]}, great job!"
    # redirect "/end"
  else
    redirect "/word"
  end
end

get "/end" do
  erb :end
end

get "/finish" do
  erb :finish
end

