require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'
require 'sinatra/flash'

enable :sessions

include Model

before('/access') do
  p "Before KÖRS, session_user_id är #{session[:user_id]}."
  if (session[:user_id] ==  nil) 
    flash[:error]= "You need to log in to see this"
    redirect('/login')
  end
end




# Display Login
#
get('/') do
  slim(:"locked/new")
end

# Display Login
#
get('/login') do
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
    redirect('/login')
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




get('/ranks') do
  @user_status = session[:user_status]

  result = ranks()
  @characters = list_characters_info()
  
  liked_characters = session[:liked_characters] || []
  unliked_characters = session[:unliked_characters] || []
  p liked_characters
  slim(:"ranks/index", locals:{characters:result,liked_characters:liked_characters,unliked_characters:unliked_characters,user_status:@user_status})

end



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
  redirect('/ranks')

end

post('/unlike/:id') do
  status = 1
  id = params[:id].to_i
  unlike(id)
  session[:unliked_characters] ||= []
  session[:unliked_characters] << id unless session[:unliked_characters].include?(id)
  redirect('/ranks')

end

get('/search/start') do
  @user_status = session[:user_status]
  slim(:'/search/start',locals:{user_status:@user_status})
end

post('/search/start') do
  name= params[:name]
  result = search(name)
  session[:search_results] = result
  redirect("/search")
end


get('/search') do
  @user_status = session[:user_status]
  results = session.delete(:search_results)
  p results
  slim(:"/search/index",locals:{results:results,user_status:@user_status})

end

get('/search/:name') do
  @user_status = session[:user_status]
  name=params[:name]
  result= select_name_where(name)

  slim(:"search/show",locals:{result:result,user_status:@user_status})
end


get('/lists') do
  @user_status = session[:user_status]
  user_id = session[:id]
  results = user_list(user_id) 
  slim(:"/lists/index", locals:{results:results,user_status:@user_status})
end

get('/lists/see-more') do
  @user_status = session[:user_status]
  user_id = session[:id]
  results = user_list(user_id)
  slim(:"/lists/see-more", locals:{results:results,user_status:@user_status})
end

post('/list/add') do
  name = params["name"]
  userId = session[:id]
  add_character_to_list(name,userId)
  redirect('/lists')

end
 


post('/delete/:name') do
  character_name = params[:name]
  userId = session[:id]
  nameId = name_to_id(character_name)
  delete_character_from_list(nameId,userId)
  redirect('/lists')
end


get('/admin_service/new') do
  @user_status = session[:user_status]
  slim(:'/admin_service/new',locals:{user_status:@user_status})
end

post('/admin_service/') do
  name = params[:name]
  chapter = params[:chapter]
  episode = params[:episode]
  year = params[:year]
  note = params[:note]
  bounty = params[:bounty]
  like = 0
  add_character_to_db(name,chapter,episode,year,note,bounty,like)
  redirect('/admin_service/new')
end

post('/delete/:name') do
  name = params[:name]
  delete_character(name)
  redirect("/ranks/index")
end

get("/ranks/:id/edit") do
  @user_status = session[:user_status]
  name = params[:name]
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute(" SELECT * FROM Characters WHERE name=?",name).first
  slim(:'/ranks/:id/edit',locals:{result:result,user_status:@user_status})
end


post("/ranks/:id/update") do
  name = params[:character_name]
  chapter = params[:chapter]
  episode = params[:episode]
  year = params[:year]
  note = params[:note]
  bounty = params[:bounty]
  id = name_to_id(params[:name])
  edit_character(name,chapter,episode,year,note,bounnty,id)
  redirect('/ranks/:id')
end



