require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'rack'

if development?
  require 'sinatra/reloader'
  require 'pry'
end

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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
  # Returns number of completed todos in the list.
  def todos_count(list)
    list[:todos].count
  end

  # returns the number of todos that are not completed in the list
  def todos_remaining_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  # Returns true if all todos in list are completed.
  def list_complete?(list)
    todos = list[:todos]
    !todos.empty? && todos_remaining_count(list).zero?
  end

  # Provides the class of the list to the views
  def list_class(list)
    'complete' if list_complete?(list)
  end

  # Yields the list and index in order: incomplete lists then complete lists
  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }

    lists
  end

  # Yields the todo and index in order: incomplete todos then complete todos
  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }

    todos
  end

  # Santizes HTML content
  def h(content)
    Rack::Utils.escape_html(content)
  end
end

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
