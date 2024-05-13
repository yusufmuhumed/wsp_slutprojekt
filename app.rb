require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'
require 'sinatra/flash'

enable :sessions

include Model
# Restricts access to certain paths if the user is not logged in.
#
# @param request [Object] The request object.
# @return [Void]
before do
  restricted_paths = ['/access', '/admin', '/ranks', '/search/start', '/lists','/admin_services', '/admin_service/new']
  if (session[:id] ==  nil && restricted_paths.include?(request.path_info))
    flash[:error]= "You need to log in before using the website"
    redirect('/login')
  end
  if session[:cooldown] && Time.now < session[:cooldown]
    remaining_seconds = (session[:cooldown] - Time.now).ceil
    flash[:error] = "Please wait #{remaining_seconds} seconds before trying to log in again."
    redirect '/login' unless request.path_info == '/login'
  end
end

# Prevents access to logout route if user is not logged in.
#
# @return [Void]
before('/showlogout') do
  if (session[:id] ==  nil)
    flash[:error] = "You need to be logged in to be able to log out"
    redirect('/login')
  end

end




# Root route, renders register site.
#
# @return [Slim::Template] The rendered template.
get('/') do
  slim(:"locked/new")
end

# Renders the login page.
get('/login') do
  session[:id] = nil
  slim(:"locked/login")
end


# Handles user login.
#
# @param username [String] The username.
# @param password [String] The password.
# @param email [String] The email address.
# @return [Integer, Boolean] The user ID if login successful, otherwise false.
# @see Model#user
# @see Model#user_admin
# @see Model#login
post('/locked/login') do
  username = params[:username]
  password = params[:password]
  email = params[:email]

  result = user(username,email)
  p result
  if user_admin(username) != nil
    user_status = user_admin(username)
    session[:user_status] = user_status["admin"]
    if login(result,password).is_a?(Integer)
      session[:id] = login(result,password)   
      if session[:user_status] == 1   
        session[:attempts] = nil
        session[:cooldown] = nil
        redirect('/admin')
      else
        session[:attempts] = nil
        session[:cooldown] = nil
        
        redirect('/access')
      end

      
      
    
    else
      session[:attempts] ||= 0
      session[:attempts] += 1
      if session[:attempts] >= 3
        session[:cooldown] = Time.now + 60
        session[:attempts] = nil
        flash[:error_login] = "You have used all attempts. Please wait 60 seconds."
      else
        flash[:error_login] = "Incorrect password. #{3 - session[:attempts]} attempts left."
      end
      redirect('/login') 
    end
  else
    session[:attempts] ||= 0
    session[:attempts] += 1
    if session[:attempts] >= 3
      session[:cooldown] = Time.now + 60
      session[:attempts] = nil
      flash[:error_login] = "You have used all attempts. Please wait 60 seconds."
    else
      flash[:error_login] = "Incorrect username or password. #{3 - session[:attempts]} attempts left."
    end
    redirect('/login') 
  end



end
# Renders the access page.
#
# @return [Slim::Template] The rendered template.
get('/access') do
  @userid=session[:id]
  p @userid
  @user_status = session[:user_status]
  slim(:"access/index",locals:{user_status:@user_status})
end

# Renders the admin page.
#
# @return [Slim::Template] The rendered template.
get('/admin') do
  @user_status = session[:user_status]
  slim(:"admin/index",locals:{user_status:@user_status}) 
end

# Logs the user out.
#
# @return [Slim::Template] The rendered template.
get('/showlogout') do
  session[:id] = nil
  slim(:logout)
end

# Handles user registration.
#
# @param username [String] The username.
# @param password [String] The password.
# @param email [String] The email address.
# @param password_confirm [String] The confirmation password.
# @see Model#register
# @return [Integer, String] The user ID if registration successful, otherwise an error message.
post("/locked") do 
  username= params[:username]
  password= params[:password]
  email= params[:email]
  password_confirm= params[:password_comfirm]
  p "hello"
  if register(username,password,email,password_confirm).is_a?(Integer)
    session[:id] = register(username,password,email,password_confirm)
    redirect('/access')
  else
    flash[:error] = register(username,password,email,password_confirm)
    p "hello"
    p flash[:error]
    redirect('/')
  end
#restful
end



# Renders the ranks page.
#
# @see Model#list_characters_info
# @see Model#liked_characters
# @return [Slim::Template] The rendered template.
get('/ranks') do
  @user_status = session[:user_status]

  result = ranks()
  @characters = list_characters_info()
  
  liked_characters = liked_characters(session[:id])
  slim(:"ranks/index", locals:{characters:result,liked_characters:liked_characters,user_status:@user_status})

end

# Renders the details of a specific character.
#
# @param id [Integer] The character ID.
# @see Model#character
# @return [Slim::Template] The rendered template.
get('/ranks/:id') do
  @user_status = session[:user_status]
  id = params[:id].to_i
  result= character(id)
  @name = result["name"]
  p @name
  slim(:"ranks/show",locals:{result:result,user_status:@user_status})
end



# Handles liking a character.
#
# @param id [Integer] The character ID.
# @see Model#user_likes
# @see Model#like

# @return [Void]
post('/ranks/like/:id') do
  status = 0
  id = params[:id].to_i
  user_likes(session[:id])
  like(id,session[:id])
  redirect('/ranks')

end

# Handles unliking a character.
#
# @param id [Integer] The character ID.
# @return [Void]
# @see Model#unlike
post('/ranks/unlike/:id') do
  status = 1
  id = params[:id].to_i
  unlike(id,session[:id])
  redirect('/ranks')

end
# Renders the search page.
#
# @return [Slim::Template] The rendered template.
get('/search/start') do
  @user_status = session[:user_status]
  slim(:'/search/start',locals:{user_status:@user_status})
end

# Handles character search.
#
# @param name [String] The character name.
# @see Model#search
# @return [Void]
post('/search/start') do
  name= params[:name]
  result = search(name)
  session[:search_results] = result
  redirect("/search")
end

# Renders search results.
#
# @return [Slim::Template] The rendered template.
get('/search') do
  @user_status = session[:user_status]
  results = session.delete(:search_results)
  p results
  slim(:"/search/index",locals:{results:results,user_status:@user_status})

end
# Renders details of a character based on name.
#
# @param name [String] The character name.
# @see Model#select_name_where
# @return [Slim::Template] The rendered template.
get('/search/:name') do
  @user_status = session[:user_status]
  name=params[:name]
  result= select_name_where(name)

  slim(:"search/show",locals:{result:result,user_status:@user_status})
end

# Renders the user's lists page.
#
# @see Model#user_list
# @return [Slim::Template] The rendered template.
get('/lists') do
  @user_status = session[:user_status]
  user_id = session[:id]
  results = user_list(user_id) 
  slim(:"/lists/index", locals:{results:results,user_status:@user_status})
end

# Renders the see-more page for user's lists.
#
# @see Model#user_list
# @return [Slim::Template] The rendered template.
get('/lists/see-more') do
  @user_status = session[:user_status]
  user_id = session[:id]
  results = user_list(user_id)
  slim(:"/lists/see-more", locals:{results:results,user_status:@user_status})
end
# Handles adding a character to the user's list.
#
# @param name [String] The character name.
# @param userId [Integer] The user ID.
# @see Model#add_character_to_list
# @return [Void]
post('/lists') do 
  name = params["name"]
  userId = session[:id]
  add_character_to_list(name,userId)
  redirect('/lists')

end
 
# Handles deleting a character from the user's list.
#
# @param character_name [String] The character name.
# @see Model#list_delete_authorization
# @see Model#delete_character_from_list
# @return [Void]
post('/lists/:name/delete') do
  character_name = params[:name]
  userId = session[:id]
  nameId = name_to_id(character_name)
  if list_delete_authorization(userId,nameId)
    delete_character_from_list(nameId,userId)
  else
    flash[:notice] = "You need to own the elemnts to be able to delete them. "
  end
  redirect('/lists')
end

# Renders the page for adding a new character by admin.
#
# @return [Slim::Template] The rendered template.
get('/admin_service/new') do
  @user_status = session[:user_status]
  slim(:'/admin_service/new',locals:{user_status:@user_status})
end
# Handles adding a new character by admin.
#
# @param name [String] The character name.
# @param chapter [String] The chapter.
# @param episode [String] The episode.
# @param year [String] The year.
# @param note [String] Additional notes.
# @param bounty [String] The bounty.
# @see Model#add_character_to_db
# @return [Void]
post('/admin_service/') do
  name = params[:name]
  chapter = params[:chapter]
  episode = params[:episode]
  year = params[:year]
  note = params[:note]
  bounty = params[:bounty]
  like = 0
  add_character_to_db(name,chapter,episode,year,note,bounty,like)
  flash[:notice] = "new character added!"
  redirect('/admin_service/new')
end
# Handles deleting a character by admin.
#
# @param id [Integer] The character id.
# @see Model#character_delete_edit_authorization
# @see Model#delete_character
# @return [Void]
post('/ranks/:id/delete') do
  id = params[:id]
  if character_delete_edit_authorization(session[:id])
    delete_character(id)
  else
    flash[:admin] = "admin key required to be able to delete or edit characters on the application"
  end
  redirect("/ranks")
end
# Renders the character edit page.
#
# @param id [Integer] The character ID.
# @see Model#character
# @return [Slim::Template] The rendered template.
get("/ranks/:id/edit") do
  @user_status = session[:user_status]
  id_character = params[:id]
  session[:id_character] = id_character
  result = character(id_character)
  p "id in edit:"
  p id_character
  slim(:'/ranks/edit',locals:{result:result,user_status:@user_status})

end

# Handles updating character details.
#
# @param character_name [String] The character name.
# @param chapter [String] The chapter.
# @param episode [String] The episode.
# @param year [String] The year.
# @param note [String] Additional notes.
# @param bounty [String] The bounty.
# @param id [Integer] The character ID.
# @see Model#character_delete_edit_authorization
# @see Model#edit_character
# @return [Void]
post("/ranks/:id/update") do
  name = params[:character_name]
  chapter = params[:chapter]
  episode = params[:episode]
  year = params[:year]
  note = params[:note]
  bounty = params[:bounty]
  id_character = session[:id_character]
  if character_delete_edit_authorization(session[:id])  
    edit_character(name,chapter,episode,year,note,bounty,id_character)
  else
    flash[:admin] = "admin key required to be able to delete or edit characters on the application"
  end
  redirect('/ranks')
end



