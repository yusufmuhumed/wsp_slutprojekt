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
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE user_name =? OR user_mail=? ",username,email).first
  user_status = user_admin(username)
  p user_status
  if result != nil
    pwdigest= result["user_pwd"]
    @id= result["id"]
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = @id
      session[:user_status] = user_status["admin"]
      
      if session[:user_status] == 1   
        
        redirect('/admin')
      else
        redirect('/access')
      end

    end
    
   
  else
    "fel lösenord"
  end
  # if BCrypt::Password.new(pwdigest) == password
  #   session[:id] = id
  #   redirect('/access')
  # else
  #   "fel lösenord"
  # end


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

  if (password == password_confirm)
    password_digest= BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/onepiece.db')
    db.execute("INSERT INTO users (user_name,user_pwd,user_mail) VALUES(?,?,?)",username,password_digest,email)
    redirect('/access')

  else
    "fel lösenord"
    
  end
end




get('/ranks/index') do
  @user_status = session[:user_status]

  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters ORDER BY likes DESC")
  @characters = db.execute("SELECT * FROM Characters")
  
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
  p id

  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE id = ?",id).first
  #result2 = db.execute("SELECT Name FROM artists WHERE ArtistID IN (SELECT ArtistId FROM albums WHERE AlbumId = ?)",id).first
  p "resultatet är: #{result}"
  slim(:"ranks/show",locals:{result:result,user_status:@user_status})
end




post('/like/:id') do
  status = 0
  id = params[:id].to_i
  p id
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  db.execute("UPDATE characters SET likes = likes + 1 WHERE id = ?", id)
  session[:liked_characters] ||= []
  session[:liked_characters] << id unless session[:liked_characters].include?(id)
  redirect(:'/ranks/index')

end

post('/unlike/:id') do
  id = params[:id].to_i
  p id
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  status = 1
  db.execute("UPDATE Characters SET likes = likes - 1 WHERE id = ?", id)
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
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE name LIKE ?", (name + '%'))
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
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE name = ?",name).first
  

  slim(:"search/show",locals:{result:result,user_status:@user_status})
end


get('/lists/index') do
  @user_status = session[:user_status]
  user_id = session[:id]
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  results = db.execute("SELECT users.user_name, Characters.name
  FROM((CharactersUsersRelations
    INNER JOIN users ON CharactersUsersRelations.UsersId = users.id)
    INNER JOIN Characters ON CharactersUsersRelations.CharactersId = Characters.id)
  WHERE UsersId = ?", user_id)
  p "test"
 
  slim(:"/lists/index", locals:{results:results,user_status:@user_status})
end

get('/lists/see-more') do
  @user_status = session[:user_status]
  user_id = session[:id]
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  results = db.execute("SELECT users.user_name, Characters.name
  FROM((CharactersUsersRelations
    INNER JOIN users ON CharactersUsersRelations.UsersId = users.id)
    INNER JOIN Characters ON CharactersUsersRelations.CharactersId = Characters.id)
  WHERE UsersId = ?", user_id)
  p "test"
  p results
  slim(:"/lists/see-more", locals:{results:results,user_status:@user_status})
end

post('/list/add') do
  name = params["name"]
  userId = session[:id]
  db = SQLite3::Database.new('db/onepiece.db')
  if is_name_a_character(name)
    nameId = db.execute("SELECT id FROM Characters WHERE name = ?",name).first[0]
    if name_already_in_list(nameId,userId) 
      p "name already in list"
      flash[:notice] = "Charcater already in list"

    else
      db.execute("INSERT INTO CharactersUsersRelations (CharactersId,UsersId) VALUES(?,?)",nameId,userId)
    end
  else
    p "character dosen't exist"
    flash[:notice] = "Character dosen't exist"

    
  end
  redirect(:'/lists/index')

end
 
post('/lists/search') do
  

end

post('/delete/:name') do
  p "hello"
  name = params[:name]
  userId = session[:id]
  db1 = SQLite3::Database.new('db/onepiece.db')
  db = SQLite3::Database.new('db/onepiece.db')

  db1.results_as_hash = true

  nameId = db1.execute("SELECT id FROM Characters WHERE name=?",name).first['id']

  p nameId
  
  db.execute("DELETE FROM CharactersUsersRelations WHERE CharactersId=? AND UsersId=?",nameId,userId)
  redirect(:'/lists/index')
end


get('/admin_service/index') do
  @user_status = session[:user_status]
  slim(:'/admin_service/index',locals:{user_status:@user_status})
end
