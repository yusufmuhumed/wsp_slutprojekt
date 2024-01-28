require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

#1. Skapa ER + databas som kan hålla användare och todos. Fota ER-diagram, 
#   lägg i misc-mapp
#2. Skapa ett formulär för att registrerara användare.
#3. Skapa ett formulär för att logga in. Om användaren lyckas logga  
#   in: Spara information i session som håller koll på att användaren är inloggad
#4. Låt inloggad användare skapa todos i ett formulär (på en ny sida ELLER på sidan som visar todos.).
#5. Låt inloggad användare updatera och ta bort sina formulär.
#6. Lägg till felhantering (meddelande om man skriver in fel user/lösen)
enable :sessions


get('/') do
  slim(:register)
end


get('/showlogin') do
  slim(:login)
end



post('/login') do
  username = params[:username]
  password = params[:password]
  email = params[:email]
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE user_name =? OR user_mail=? ",username,email).first
  pwdigest= result["pwdigest"]
  id= result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect('/todos')
  else
    "fel lösenord"
  end


end

get('/todos') do 
  id = session[:id].to_i
  db = SQLite3::Database.new('db/onepiece.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM characters WHERE user_id = ?",id)
  p   "alla todos från result #{result}"
  slim(:"todos/index", locals:{todos:result})
end

post("/users/new") do
 username= params[:username]
 password= params[:password]
 email= params[:email]
 password_confirm= params[:password_comfirm]

  if (password == password_confirm)
    password_digest= BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/onepiece.db')
    db.execute("INSERT INTO users (user_name,user_pwd,user_mail) VALUES(?,?)",username,password_digest,email)
    redirect('/')

  else
    "fel lösenord"
    
  end
end