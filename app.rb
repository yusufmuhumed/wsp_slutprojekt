require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'


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
      
      if user_status["admin"] == 1
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
  slim(:"access/index")
end

get('/admin') do
  slim(:"admin/index") 
end


get('/showlogout') do 
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
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters ORDER BY likes DESC")
  @characters = db.execute("SELECT * FROM Characters")
  
  liked_characters = session[:liked_characters] || []
  unliked_characters = session[:unliked_characters] || []
  p liked_characters
  #result2 = db.execute("SELECT likes FROM Characters")
  slim(:"ranks/index", locals:{characters:result,liked_characters:liked_characters,unliked_characters:unliked_characters})

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
  id = params[:id].to_i
  p id

  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE id = ?",id).first
  #result2 = db.execute("SELECT Name FROM artists WHERE ArtistID IN (SELECT ArtistId FROM albums WHERE AlbumId = ?)",id).first
  p "resultatet är: #{result}"
  slim(:"ranks/show",locals:{result:result})
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
  slim(:'search/start')
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
  results = session.delete(:search_results)
  p results
  slim(:"search/index",locals:{results:results})

end

get('/search/:name') do
  name=params[:name]
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE name = ?",name).first
  

  slim(:"search/show",locals:{result:result})
end


get('/lists/index') do
  user_id = session[:id]
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  results = db.execute("SELECT users.user_name, Characters.name
  FROM((CharactersUsersRelations
    INNER JOIN users ON CharactersUsersRelations.UsersId = users.id)
    INNER JOIN Characters ON CharactersUsersRelations.CharactersId = Characters.id)
  WHERE UsersId = ?", user_id)
  p "test"
  p session[:id]
  slim(:"/lists/index", locals:{results:results})
end 

post('/list/add') do
  name = params["name"]
  userId = session[:id]
  db = SQLite3::Database.new('db/onepiece.db')

  nameId = db.execute("SELECT id FROM Characters WHERE name = ?",name).first[0]
  if nameId == nil
    p "hello"
   
  elsif name_already_in_list(nameId,userId) 
    p "hello"  
  else
    db.execute("INSERT INTO CharactersUsersRelations (CharactersId,UsersId) VALUES(?,?)",nameId,userId)

    
  end
  redirect(:'/lists/index')

end

post('/lists/search') do
  

end



