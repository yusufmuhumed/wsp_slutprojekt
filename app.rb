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
  pwdigest= result["user_pwd"]
  id= result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/access')
  else
    "fel lösenord"
  end


end

get('/access') do 
  slim(:"access/index")
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
  result = db.execute("SELECT * FROM Characters")
  #result2 = db.execute("SELECT likes FROM Characters")
  slim(:"ranks/index", locals:{characters:result})

end


get('/ranks/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/onepiece.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM Characters WHERE id = ?",id).first
  #result2 = db.execute("SELECT Name FROM artists WHERE ArtistID IN (SELECT ArtistId FROM albums WHERE AlbumId = ?)",id).first
  p "resultatet är: #{result}"
  slim(:"ranks/show",locals:{result:result})
end


get('/search/index') do
  slim(:"search/index")
end




# post('/access/search') do
  

# end


