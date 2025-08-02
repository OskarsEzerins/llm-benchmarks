require 'date'

class App
  def initialize
    @books = []
    @people = []
    @rentals = []
    @person_id_counter = 1
    @book_id_counter = 1
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each do |bk|
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.correct_name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a student (press 1) or a teacher (press 2)? '
    choice = gets.chomp

    case choice
    when '1'
      create_teacher
    when '2'
      create_student
    else
      puts 'Invalid choice. Please select 1 or 2.'
      create_person
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    while name.nil? || name.empty?
      puts 'Name cannot be empty.'
      print 'Name: '
      name = gets.chomp
    end

    print 'Age: '
    age_str = gets.chomp
    age = nil
    until age_str.match?(/^\d+$/)
      puts 'Invalid age. Please enter a positive integer.'
      print 'Age: '
      age_str = gets.chomp
    end
    age = age_str.to_i

    parent_permission = nil
    loop do
      print 'Has parent permission? (Y/N): '
      perm_input = gets.chomp.upcase
      if perm_input == 'Y'
        parent_permission = true
        break
      elsif perm_input == 'N'
        parent_permission = false
        break
      else
        puts 'Invalid input. Please enter Y or N.'
      end
    end

    student = Student.new(name, age, parent_permission: parent_permission)
    @people << student
    puts "#{student.name} the student created successfully."
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    while name.nil? || name.empty?
      puts 'Name cannot be empty.'
      print 'Name: '
      name = gets.chomp
    end

    print 'Age: '
    age_str = gets.chomp
    age = nil
    until age_str.match?(/^\d+$/)
      puts 'Invalid age. Please enter a positive integer.'
      print 'Age: '
      age_str = gets.chomp
    end
    age = age_str.to_i

    print 'Specialization: '
    specialization = gets.chomp
    specialization = nil if specialization.empty?

    teacher = Teacher.new(name, specialization, age)
    @people << teacher
    puts "#{teacher.name} the teacher created successfully."
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    while title.nil? || title.empty?
      puts 'Title cannot be empty.'
      print 'Title: '
      title = gets.chomp
    end

    print 'Author: '
    author = gets.chomp
    while author.nil? || author.empty?
      puts 'Author cannot be empty.'
      print 'Author: '
      author = gets.chomp
    end

    book = Book.new(title, author)
    @books << book
    puts "#{book.title} by #{book.author} created successfully."
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    if @people.empty?
      puts 'No people registered to rent books.'
      return
    end

    puts 'Select a book by its index:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    print 'Book index: '
    book_index_str = gets.chomp
    book_index = book_index_str.to_i

    unless book_index.between?(0, @books.length - 1)
      puts 'Invalid book index.'
      return
    end
    selected_book = @books[book_index]

    puts 'Select a person by their index:'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] ID: #{p.id}, Name: #{p.correct_name}, Age: #{p.age}" }
    print 'Person index: '
    person_index_str = gets.chomp
    person_index = person_index_str.to_i

    unless person_index.between?(0, @people.length - 1)
      puts 'Invalid person index.'
      return
    end
    selected_person = @people[person_index]

    rental = Rental.new(selected_book, selected_person, Date.today)
    @rentals << rental
    selected_book.rentals << rental
    selected_person.rentals << rental
    puts "Rental created: #{selected_book.title} rented by #{selected_person.correct_name} on #{rental.date}."
  end

  def list_rentals
    print 'Enter the ID of the person to list rentals for: '
    pid_str = gets.chomp
    pid = pid_str.to_i

    person_rentals = @rentals.select { |r| r.person.id == pid }

    if person_rentals.empty?
      puts "No rentals found for person with ID #{pid}."
    else
      puts "Rentals for person with ID #{pid}:"
      person_rentals.each do |r|
        puts "- Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}"
      end
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(book, person, date)
    @date = date
    @book = book
    @person = person
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
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
    stud.assign_classroom(self) unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
  end

  private

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(name, age, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = nil
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    @classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(name, specialization, age = 0)
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end