require 'sinatra'
require 'tilt/erubis'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# GET   /lists      -> view all lists
# GET   /lists/new  -> new list form
# POST  /lists      -> create new list
# GET   /lists/1    -> view a single list

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:id' do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list, layout: :layout
end

helpers do
  # Return an error message if name is invalid
  def error_for_list_name(list_name)
    if !(1..200).cover? list_name.size
      return 'List name must be between 1 and 200 characters'
    elsif session[:lists].any? { |list| list[:name] == list_name }
      return 'List name must be unique.'
    end

    nil
  end
end
