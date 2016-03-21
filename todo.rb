require 'sinatra'
require 'sinatra/content_for'
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

# View the contents of one list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo(todo_name, @list)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = 'The todo was added.'
    
    redirect "/lists/#{@list_id}"
  end
end

# View the form for editing a list
get '/lists/:id/edit' do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list name has been updated.'
    redirect "/lists/#{id}"
  end
end

# Delete the specified list.
post '/lists/:id/destroy' do
  id = params[:id].to_i
  deleted_list = session[:lists].delete_at(id)
  session[:success] = "The \"#{deleted_list[:name]}\" list has been deleted."

  redirect '/lists'
end

helpers do
  # Return an error message if name is invalid
  def error_for_list_name(name)
    if !(1..200).cover? name.size
      'List name must be between 1 and 200 characters'
    elsif session[:lists].any? { |list| list[:name] == name }
      'List name must be unique.'
    end
  end

  # Return an error if name is invalid
  def error_for_todo(name, list)
    if !(1..200).cover? name.size
      return 'Todo name must be between 1 and 200 characters'
    end
  end
end
