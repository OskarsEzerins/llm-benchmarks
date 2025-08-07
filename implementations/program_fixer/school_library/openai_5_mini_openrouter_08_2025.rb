class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] Name: #{human.name}, ID: #{human.id}, Age: #{human.age}"
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]:'
    choice = gets.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option. Please choose 1 or 2.'
    end
  end

  def create_student
    name = ''
    loop do
      print 'Name: '
      name = gets&.chomp.to_s
      break unless name.strip.empty?
      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets&.chomp
      begin
        age = Integer(input)
        if age.negative?
          puts 'Age must be a non-negative integer.'
        else
          break
        end
      rescue ArgumentError, TypeError
        puts 'Please enter a valid integer for age.'
      end
    end

    perm = nil
    loop do
      print 'Parent permission? [Y/N]: '
      answer = gets&.chomp.to_s.upcase
      if %w[Y N].include?(answer)
        perm = answer == 'Y'
        break
      else
        puts 'Please enter Y or N.'
      end
    end

    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    name = ''
    loop do
      print 'Name: '
      name = gets&.chomp.to_s
      break unless name.strip.empty?
      puts 'Name cannot be empty.'
    end

    age = nil
    loop do
      print 'Age: '
      input = gets&.chomp
      begin
        age = Integer(input)
        if age.negative?
          puts 'Age must be a non-negative integer.'
        else
          break
        end
      rescue ArgumentError, TypeError
        puts 'Please enter a valid integer for age.'
      end
    end

    print 'Specialization: '
    spec = gets&.chomp.to_s

    teacher = Teacher.new(age, spec, name)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    title = ''
    loop do
      print 'Title: '
      title = gets&.chomp.to_s
      break unless title.strip.empty?
      puts 'Title cannot be empty.'
    end

    author = ''
    loop do
      print 'Author: '
      author = gets&.chomp.to_s
      break unless author.strip.empty?
      puts 'Author cannot be empty.'
    end

    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    if @people.empty?
      puts 'No people available to rent a book.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title} by #{b.author}" }
    book_index = nil
    loop do
      print 'Book number: '
      input = gets&.chomp
      begin
        book_index = Integer(input)
        if book_index >= 0 && book_index < @books.length
          break
        else
          puts 'Invalid book number. Try again.'
        end
      rescue ArgumentError, TypeError
        puts 'Please enter a valid integer.'
      end
    end

    puts 'Select a person from the following list by number (not ID)'
    @people.each_with_index { |p, i| puts "#{i}: [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_index = nil
    loop do
      print 'Person number: '
      input = gets&.chomp
      begin
        person_index = Integer(input)
        if person_index >= 0 && person_index < @people.length
          break
        else
          puts 'Invalid person number. Try again.'
        end
      rescue ArgumentError, TypeError
        puts 'Please enter a valid integer.'
      end
    end

    print 'Date (YYYY-MM-DD) [leave blank for today]: '
    date_input = gets&.chomp
    date = if date_input.nil? || date_input.strip.empty?
             Date.today.to_s
           else
             date_input
           end

    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    input = gets&.chomp
    begin
      pid = Integer(input)
    rescue ArgumentError, TypeError
      puts 'Invalid ID format.'
      return
    end

    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'No person found with that ID.'
      return
    end

    if p_obj.rentals.empty?
      puts 'No rentals for this person.'
      return
    end

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end
end

# Nameable and Decorators
class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement the correct_name method'
  end
end

class Decorator < Nameable
  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    name = super.to_s
    name[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super.to_s
    # Capitalize each word for nicer output
    name.split(' ').map(&:capitalize).join(' ')
  end
end

# Rental, Book, Classroom, Person, Student, Teacher
class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self unless book.rentals.include?(self)
    person.rentals << self unless person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
    @age = age.to_i
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name.to_s
  end

  def add_rental(book, date)
    Rental.new(date, book, self)
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end