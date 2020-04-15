require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        
        self.type_translation = true
        self.results_as_hash = true
    end
end

class User
    attr_accessor :id, :fname, :lname
    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def self.all
      arr = QuestionsDatabase.instance.execute(<<-SQL)
        SELECT
          *
        FROM
          users
      SQL

      arr.map { |inst| User.new(inst) }
    end 


    def self.find_by_id(id)
      arr = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
          *
        FROM
          users
        WHERE
          id = ?
      SQL

      User.new(arr.first)

    end 
    
    def self.find_by_name(fname, lname)
      arr = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        SELECT
          *
        FROM
          users
        WHERE
          fname = ? AND
          lname = ?
      SQL

      User.new(arr.first)
    end 

    def authored_questions
        Question.find_by_author_id(self.id)
    end
    
    def authored_replies
        Reply.find_by_user_id(self.id)
    end
    
    def followed_questions
        QuestionFollow.followed_questions_for_user_id(self.id)
    end 

    def liked_questions
        QuestionLike.liked_questions_for_user_id(self.id)
    end

    def average_karma
        arr = QuestionsDatabase.instance.execute(<<-SQL, self.id)
            SELECT
                COUNT(DISTINCT questions.id) AS num_questions, COUNT(question_likes.id) AS num_likes
            FROM
                questions
            LEFT OUTER JOIN
                question_likes ON question_likes.question_id = questions.id
            WHERE
                ? = questions.author_id
            SQL

        unless arr.first['num_questions'] == 0 
            arr.first['num_likes'] / arr.first['num_questions'] 
        else
            raise "#{self.fname} has no questions asked"
        end 
    end

    def save
        unless self.id
                #INSERT
            QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
            INSERT INTO
                users(fname, lname)
            VALUES
                (?, ?)
            SQL
            self.id = QuestionsDatabase.instance.last_insert_row_id
        else 
            #UPDATE
            QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname, self.id)
                UPDATE
                    users
                SET    
                    fname = ?,
                    lname = ?
                WHERE 
                    id = ?
            SQL
        end
    end 
end

class Question
    attr_accessor :id, :title, :body, :author_id
    
    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end 

  def self.all
    arr = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
    SQL

    arr.map { |inst| Question.new(inst) }
  end 

    def self.find_by_id(id)
        arr = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
            SQL
        
        Question.new(arr.first)
    end 
    
    def self.find_by_author_id(author_id)
        arr = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?
        SQL

        arr.map {|inst| Question.new(inst) }
    end 
  
    def author
        User.find_by_id(self.author_id)
    end 

    def replies
        Reply.find_by_question_id(self.id)
    end 

    def followers
      QuestionFollow.followers_for_question_id(self.id)
    end 

    def self.most_followed(n)
        QuestionFollow.most_followed_question(n)
    end

    def likers
        QuestionLike.likers_for_question_id(self.id)
    end

    def num_likes
        QuestionLike.likers_for_question_id(self.id).size
    end

    def self.most_liked(n)
        QuestionLike.most_liked_question(n)
    end


    def save
        unless self.id
                #INSERT
            QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.author_id)
            INSERT INTO
                questions(title, body, author_id)
            VALUES
                (?, ?, ?)
            SQL
            self.id = QuestionsDatabase.instance.last_insert_row_id
        else 
            #UPDATE
            QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.author_id, self.id)
                UPDATE
                    questions
                SET    
                    title = ?,
                    body = ?,
                    author_id = ?
                WHERE 
                    id = ?
            SQL
        end
    end 

end 

class Reply
    attr_accessor :id, :reply_body, :parent_reply_id, :user_id, :question_id

  def initialize(options)
    @id = options['id']
    @reply_body = options['reply_body']
    @parent_reply_id = options['parent_reply_id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end 

  def self.all
    arr = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      *
    FROM
      replies
    SQL

    arr.map { |inst| Reply.new(inst) }

  end 

  def self.find_by_id(id)
    arr = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL

    Reply.new(arr.first)
  end 
  
  def self.find_by_user_id(user_id)
    arr = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT  
            *
        FROM
            replies
        WHERE
            user_id = ?
    SQL

    arr.map { |inst| Reply.new(inst) }
  end 
  
  def self.find_by_question_id(question_id)
    arr = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT  
            *
        FROM
            replies
        WHERE
            question_id = ?
    SQL

    arr.map { |inst| Reply.new(inst) }
  end 


    def author
        User.find_by_id(user_id)
    end 

    def question
        Question.find_by_id(question_id)
    end 

    def parent_reply
        Reply.find_by_id(parent_reply_id)    
    end 

    def child_replies
        arr = QuestionsDatabase.instance.execute(<<-SQL, self.id)
            SELECT
                *
            FROM 
                replies
            WHERE
                parent_reply_id = ?
        SQL
        arr.map { |inst| Reply.new(inst) }
    end

    def save
        unless self.id
                #INSERT
            QuestionsDatabase.instance.execute(<<-SQL, self.reply_body, self.parent_reply_id, self.user_id, self.question_id)
            INSERT INTO
                replies(reply_body, parent_reply_id, user_id, question_id)
            VALUES
                (?, ?, ?, ?)
            SQL
            self.id = QuestionsDatabase.instance.last_insert_row_id
        else 
            #UPDATE
            QuestionsDatabase.instance.execute(<<-SQL, self.reply_body, self.parent_reply_id, self.user_id, self.question_id, self.id)
                UPDATE
                    replies
                SET    
                    reply_body = ?,
                    parent_reply_id = ?,
                    user_id = ?,
                    question_id = ?
                WHERE 
                    id = ?
            SQL
        end
    end 

end 

class QuestionFollow
    attr_accessor :id, :question_id, :user_id

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end

    def self.all
        arr = QuestionsDatabase.instance.execute(<<-SQL)
            SELECT
                *
            FROM
                question_follows
        SQL

        arr.map {|inst| QuestionFollow.new(inst)}
    end
    
    def self.followers_for_question_id(question_id)
        arr = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                users.id, users.fname, users.lname
            FROM
                users
            JOIN
                question_follows ON users.id = question_follows.user_id
            JOIN
                questions ON question_follows.question_id = questions.id
            WHERE
                question_id = ?
        SQL

        arr.map {|inst| User.new(inst)}
    end
    
    
    def self.most_followed_question(n)
        arr = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
        questions.*, COUNT(questions.author_id)
        FROM
        questions
        JOIN
        question_follows ON question_follows.question_id = questions.id
        GROUP BY
        questions.id
        ORDER BY
        COUNT(questions.author_id) DESC LIMIT ? 
        SQL
        
        arr.map {|inst| Question.new(inst)}
    end 
    
end

class QuestionLike
    
    attr_accessor :id, :user_id, :question_id
    def initialize(options_hash)
        @id = options_hash['id']
        @user_id = options_hash['user_id']
        @question_id = options_hash['question_id']
    end 
    
    def self.likers_for_question_id(question_id)
        arr = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            users.*
        FROM
            users
        JOIN
            question_likes ON users.id = question_likes.user_id
        JOIN
            questions ON question_likes.question_id = questions.id
        WHERE
            question_id = ?
        SQL
        
        arr.map {|inst| User.new(inst)}
    end
    
    def self.liked_questions_for_user_id(user_id)
        arr = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            questions.*
        FROM
            questions
        JOIN
            question_likes ON questions.id = question_likes.question_id
        JOIN
             users ON question_likes.user_id = users.id
        WHERE
            user_id = ?
        SQL
        
        arr.map {|inst| Question.new(inst)}
    end 
    
    def self.most_liked_question(n)
        arr = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                questions.*, COUNT(questions.author_id)
            FROM
                questions
            JOIN
                question_likes ON question_likes.question_id = questions.id
            GROUP BY
                questions.id
            ORDER BY
                COUNT(questions.author_id) DESC LIMIT ? 
        SQL
        
        arr.map {|inst| Question.new(inst)}
    end 
    
    
end 




