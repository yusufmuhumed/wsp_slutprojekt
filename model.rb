require "sqlite3"
require "bcrypt"

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
   end

def list_name()
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT name FROM Characters")
   return result
 
end

def user(username,email)
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT * FROM users WHERE user_name =? OR user_mail=? ",username,email).first
   return result
end


def user_admin(user)
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT admin FROM users WHERE user_name=?",user).first
   return result
end

def login(result,user_status,password)
   if result != nil
      pwdigest= result["user_pwd"]
      @id= result["id"]
      if BCrypt::Password.new(pwdigest) == password
        session[:id] = @id
        session[:user_status] = user_status["admin"]
        return true
      else
         return false
      end

   end

end


# username="yusuf"
# user_status= user_admin("yusuf")
# p user_status

# p user_status["admin"]

def name_already_in_list(nameId,userId)
   db = SQLite3::Database.new('db/onepiece.db')
   result = db.execute("SELECT UsersId FROM CharactersUsersRelations WHERE CharactersId =? AND UsersId=?",nameId,userId)
   p result
   if result.length <= 0 && result.length <= 1
      return false
   else
      return true
   end
end

def is_name_a_character(name)
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT name FROM Characters WHERE name =? ",name)
   p result
   if result == [] 
      return false
   else
      return true
   end

end









