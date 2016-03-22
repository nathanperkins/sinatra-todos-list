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
get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  todo_name = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_todo(todo_name)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = 'The todo was added.'

    redirect "/lists/#{@list_id}"
  end
end

# Delete the todo from the list
post '/lists/:list_id/todos/:todo_id/destroy' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
  todo_id = params[:todo_id].to_i

  deleted_todo = list[:todos].delete_at(todo_id)
  session[:success] = "\"#{deleted_todo[:name]}\" has been deleted."

  redirect "/lists/#{list_id}"
end

# Update the status of the todo
post '/lists/:list_id/todos/:todo_id' do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  todo_id = params[:todo_id].to_i
  todo = list[:todos][todo_id]

  todo[:completed] = params[:completed] == 'true'
  session[:success] = 'The todo has been updated!'

  redirect "/lists/#{list_id}"
end

# View the form for editing a list
get '/lists/:list_id/edit' do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  erb :edit_list, layout: :layout
end

# Update an existing todo list
post '/lists/:list_id' do
  list_name = params[:list_name].strip
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list name has been updated.'
    redirect "/lists/#{list_id}"
  end
end

# Mark all todos as completed
post '/lists/:list_id/complete_all' do
  if params[:complete_all] == 'true'
    list_id = params[:list_id].to_i
    list = session[:lists][list_id]
    
    list[:todos].each { |todo| todo[:completed] = true }
    session[:success] = 'All todos were marked completed.'
    
    redirect "/lists/#{list_id}"
  end
end

# Delete the specified list.
post '/lists/:list_id/destroy' do
  list_id = params[:list_id].to_i
  deleted_list = session[:lists].delete_at(list_id)
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
  def error_for_todo(name)
    unless (1..200).cover? name.size
      return 'Todo name must be between 1 and 200 characters'
    end
  end
  
  def count_completed(list)
    list[:todos].count { |todo| todo[:completed] }
  end
  
  def all_completed?(list)
    todos = list[:todos]
    todos.size > 0 && count_completed(list) == todos.size
  end
end
