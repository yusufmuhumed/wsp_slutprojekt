require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'
require 'sinatra/flash'

enable :sessions




get('/') do
  slim(:"locked/new")
end


get('/showlogin') do
  slim(:"locked/login")
end



post('/locked/login') do
  username = params[:username]
  password = params[:password]
  email = params[:email]
  result = user(username,email)
  user_status = user_admin(username)
  
  if login(result,user_status,password)    
    if session[:user_status] == 1   
      
      redirect('/admin')
    else
      redirect('/access')
    end

    
    
   
  else
    "fel lösenord"
  end


end

get('/access') do
  @user_status = session[:user_status]
  slim(:"access/index",locals:{user_status:@user_status})
end

get('/admin') do
  @user_status = session[:user_status]
  slim(:"admin/index",locals:{user_status:@user_status}) 
end


get('/showlogout') do
  session[:id] = 0
  slim(:logout)
end

post("/locked/new") do
  username= params[:username]
  password= params[:password]
  email= params[:email]
  password_confirm= params[:password_comfirm]

  if register(username,password,email,password_confirm) 
    redirect('/access')
  else
    redirect('/')
  end

  
end




get('/ranks/index') do
  @user_status = session[:user_status]

  result = ranks()
  @characters = list_characters_info()
  
  liked_characters = session[:liked_characters] || []
  unliked_characters = session[:unliked_characters] || []
  p liked_characters
  #result2 = db.execute("SELECT likes FROM Characters")
  slim(:"ranks/index", locals:{characters:result,liked_characters:liked_characters,unliked_characters:unliked_characters,user_status:@user_status})

end


# post('/like/:id') do
#   id = params[:id].to_i
#   db = SQLite3::Database.new("db/onepiece.db")
#   db.results_as_hash = true
#   db.execute("UPDATE Characters SET likes = likes + 1 WHERE id = ?", id)
#   session[:liked_characters] ||= []
#   session[:liked_characters] << id unless session[:liked_characters].include?(id)
#   redirect('/ranks/index')
# end

get('/ranks/:id') do
  @user_status = session[:user_status]
  id = params[:id].to_i
  result= character(id)
  slim(:"ranks/show",locals:{result:result,user_status:@user_status})
end




post('/like/:id') do
  status = 0
  id = params[:id].to_i
  
  like(id)
  session[:liked_characters] ||= []
  session[:liked_characters] << id unless session[:liked_characters].include?(id)
  redirect(:'/ranks/index')

end

post('/unlike/:id') do
  status = 1
  id = params[:id].to_i
  unlike(id)
  session[:unliked_characters] ||= []
  session[:unliked_characters] << id unless session[:unliked_characters].include?(id)
  redirect(:'/ranks/index')

end

get('/search/start') do
  @user_status = session[:user_status]
  slim(:'search/start',locals:{user_status:@user_status})
end

post('/search/start') do
  name= params[:name]
  result = search(name)
  p result
  session[:search_results] = result
  redirect(:"search/index")
end


get('/search/index') do
  @user_status = session[:user_status]
  results = session.delete(:search_results)
  p results
  slim(:"search/index",locals:{results:results,user_status:@user_status})

end

get('/search/:name') do
  @user_status = session[:user_status]
  name=params[:name]
  result= select_name_where(name)

  slim(:"search/show",locals:{result:result,user_status:@user_status})
end


get('/lists/index') do
  @user_status = session[:user_status]
  user_id = session[:id]
  results = user_list(user_id)
  p "test"
 
  slim(:"/lists/index", locals:{results:results,user_status:@user_status})
end

get('/lists/see-more') do
  @user_status = session[:user_status]
  user_id = session[:id]
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  results = user_list(user_id)
  p "test"
  p results
  slim(:"/lists/see-more", locals:{results:results,user_status:@user_status})
end

post('/list/add') do
  name = params["name"]
  userId = session[:id]
  add_character_to_list(name,userId)
  redirect(:'/lists/index')

end
 
post('/lists/search') do
  

end

post('/delete/:name') do
  p "hello"
  character_name = params[:name]
  userId = session[:id]
  db1 = SQLite3::Database.new('db/onepiece.db')
  db = SQLite3::Database.new('db/onepiece.db')

  db1.results_as_hash = true

  nameId = name_to_id(character_name)

  delete_character_from_list(nameId,userId)
  
  redirect(:'/lists/index')
end


get('/admin_service/index') do
  @user_status = session[:user_status]
  slim(:'/admin_service/index',locals:{user_status:@user_status})
end

post('/delete/:name') do
  name = params[:name]
  delete_character(name)
  redirect(:"/ranks/index")
end

get("/:name/edit") do
  @user_status = session[:user_status]
  name = params[:name]
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute(" SELECT * FROM Characters WHERE name=?",name).first
  slim(:'/ranks/edit',locals:{result:result,user_status:@user_status})
end