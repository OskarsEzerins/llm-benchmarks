require 'date'

class App
  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
      return
    end
    @books.each { |bk| puts "title: #{bk.title}, author: #{bk.author}" }
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)?'
    print 'Enter 1 or 2: '
    choice = gets&.chomp

    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection. Please enter 1 for student or 2 for teacher.'
    end
  end

  def create_student
    name = ask_name
    age = ask_age
    parent_permission = ask_parent_permission
    student = Student.new(age, nil, name, parent_permission: parent_permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = ask_name
    age = ask_age
    print 'Specialization: '
    specialization = (gets&.chomp || '').strip
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = (gets&.chomp || '').strip
    title = 'Untitled' if title.empty?
    print 'Author: '
    author = (gets&.chomp || '').strip
    author = 'Unknown' if author.empty?
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available to rent.'
      return
    end
    if @people.empty?
      puts 'No people available to create a rental.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title} by #{b.author}" }
    print 'Book number: '
    book_index = safe_to_i(gets)

    unless book_index && book_index >= 0 && book_index < @books.length
      puts 'Invalid book selection.'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    print 'Person number: '
    person_index = safe_to_i(gets)

    unless person_index && person_index >= 0 && person_index < @people.length
      puts 'Invalid person selection.'
      return
    end

    print 'Date (YYYY-MM-DD, leave empty for today): '
    date_input = (gets&.chomp || '').strip
    date_str = if date_input.empty?
                 Date.today.to_s
               else
                 begin
                   Date.parse(date_input).to_s
                 rescue ArgumentError
                   puts 'Invalid date, using today.'
                   Date.today.to_s
                 end
               end

    rental = Rental.new(date_str, @books[book_index], @people[person_index])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    if @people.empty?
      puts 'No people registered.'
      return
    end
    print 'ID of person: '
    pid = safe_to_i(gets)
    unless pid
      puts 'Invalid ID.'
      return
    end
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found.'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals found for this person.'
      return
    end
    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title} by #{r.book.author}" }
  end

  private

  def ask_name
    print 'Name: '
    name = (gets&.chomp || '').strip
    name.empty? ? 'Unknown' : name
  end

  def ask_age
    age = nil
    loop do
      print 'Age: '
      input = gets&.chomp
      age = Integer(input || '') rescue nil
      break if age && age >= 0
      puts 'Please enter a valid non-negative integer for age.'
    end
    age
  end

  def ask_parent_permission
    loop do
      print 'Parent permission? [Y/N]: '
      resp = (gets&.chomp || '').strip.upcase
      return true if resp == 'Y'
      return false if resp == 'N'
      puts 'Please enter Y or N.'
    end
  end

  def safe_to_i(str)
    Integer(str&.chomp || '') rescue nil
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    name = super
    return '' if name.nil?
    name.length > 10 ? name[0, 10] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = @nameable.correct_name
    return '' if name.nil?
    name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
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
    stud.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(age, name = 'Unknown', parent_permission: true)
    @id = Random.rand(1..1000)
    @name = (name.nil? || name.strip.empty?) ? 'Unknown' : name
    @age = age.to_i
    @parent_permission = !!parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || @parent_permission
  end

  def correct_name
    @name
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
  attr_accessor :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name)
    super(age, name)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end