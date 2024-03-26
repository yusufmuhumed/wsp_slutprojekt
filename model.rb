require "sqlite3"


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

def user_admin(user)
   db = SQLite3::Database.new('db/onepiece.db')
   db.results_as_hash = true
   result = db.execute("SELECT admin FROM users WHERE user_name=?",user).first
   return result
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


p name_already_in_list(1032,4)







