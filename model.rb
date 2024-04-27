require "sqlite3"
require "bcrypt"

module Model
   def connect_to_db(path)
      db = SQLite3::Database.new(path)
      db.results_as_hash = true
      return db
      
   end

   def list_name()
      db= connect_to_db('db/onepiece.db')
      result = db.execute("SELECT name FROM Characters")
      return result
   
   end

   def list_characters_info()
      db = SQLite3::Database.new('db/onepiece.db')
      characters = db.execute("SELECT * FROM Characters")
      return characters
   end

   def user(username,email)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM users WHERE user_name =? OR user_mail=? ",username,email).first
      return result
   end


   def user_admin(user)
      db = connect_to_db('db/onepiece.db')
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
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT name FROM Characters WHERE name =? ",name)
      p result
      if result == [] 
         return false
      else
         return true
      end

   end


   def register(username,password,email,password_confirm)
      if password == password_confirm
         password_digest= BCrypt::Password.create(password)
         db = SQLite3::Database.new('db/onepiece.db')
         db.execute("INSERT INTO users (user_name,user_pwd,user_mail) VALUES(?,?,?)",username,password_digest,email)
         return true
   
      else
         return false
      
      end
   end

   def ranks()
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters ORDER BY likes DESC")
      return result
   end


   def character(id)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE id = ?",id).first
      return result
   end

   def like(id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE characters SET likes = likes + 1 WHERE id = ?", id)
   end

   def unlike(id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE Characters SET likes = likes - 1 WHERE id = ?", id)
   end

   def search(name)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE name LIKE ?", (name + '%'))
      return result
   end

   def select_name_where(name)
      db = connect_to_db('db/onepiece.db')
      result = db.execute("SELECT * FROM Characters WHERE name = ?",name).first
      return result
   end

   def user_list(user_id)
      db = connect_to_db('db/onepiece.db')
      results = db.execute("SELECT users.user_name, Characters.name
      FROM((CharactersUsersRelations
         INNER JOIN users ON CharactersUsersRelations.UsersId = users.id)
         INNER JOIN Characters ON CharactersUsersRelations.CharactersId = Characters.id)
      WHERE UsersId = ?", user_id)
      return results
   end

   def add_character_to_list(name,userId)
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
   end

   def name_to_id(name)
      db = connect_to_db('db/onepiece.db')
      nameId = db.execute("SELECT id FROM Characters WHERE name=?",name).first['id']
      return nameId
   end

   def name_to_id2(name)
      db = connect_to_db('db/onepiece.db')
      nameId = db.execute("SELECT id FROM Characters WHERE name=?",name).first
      return nameId
   end

   def delete_character_from_list(nameId,userId)
      db = SQLite3::Database.new('db/onepiece.db')
      db.execute("DELETE FROM CharactersUsersRelations WHERE CharactersId=? AND UsersId=?",nameId,userId)
   end


   def delete_character(name)
      db = connect_to_db('db/onepiece.db')
      db.execute("DELETE FROM Characters WHERE name=?",name)
   end




   def edit_character(name,chapter,episode,year,note,bounnty,id)
      db = connect_to_db('db/onepiece.db')
      db.execute("UPDATE Characters name=?, chapter=?, episode=?, year=?, note=?, bounty=?, likes=?
      WHERE  id=?",name,chapter,episode,year,note,bounty,0,id)
   end


   def add_character_to_db(name,chapter,episode,year,note,bounty,like)
      db = connect_to_db('db/onepiece.db')
      db.execute("INSERT INTO Characters (name,chapter,episode,year,note,bounty,likes) VALUES(?,?,?,?,?,?,?)",name,chapter,episode,year,note,bounty,like)
   end

   

end

