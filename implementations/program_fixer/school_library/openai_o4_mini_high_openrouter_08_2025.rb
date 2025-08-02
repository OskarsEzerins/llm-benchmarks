class Nameable
  def correct_name
    nil
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
    super()[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super().capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title
    @author = author
    @rentals = []
  end

  def add_rental(date, person)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students << student unless @students.include?(student)
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

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

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @classroom = classroom
    classroom.add_student(self) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.add_student(self) unless room.students.include?(self)
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

class App
  def initialize
    @books = []
    @people = []
  end

  def list_books
    if @books.empty?
      puts 'No books available'
    else
      @books.each { |book| puts "Title: #{book.title}, Author: #{book.author}" }
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |person|
        puts "[#{person.class}] ID: #{person.id}, Name: #{person.name}, Age: #{person.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input number]: '
    choice = gets.chomp
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid choice'
    end
  end

  def create_student
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.strip.empty?
    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /^\d+$/
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a valid number.'
      end
    end
    perm = nil
    loop do
      print 'Has parent permission? [Y/N]: '
      input = gets.chomp.upcase
      if ['Y', 'N'].include?(input)
        perm = input == 'Y'
        break
      else
        puts 'Invalid input. Please enter Y or N.'
      end
    end
    student = Student.new(age, nil, name, parent_permission: perm)
    @people << student
    puts 'Person created successfully'
  end

  def create_teacher
    print 'Name: '
    name = gets.chomp
    name = 'Unknown' if name.strip.empty?
    age = nil
    loop do
      print 'Age: '
      input = gets.chomp
      if input =~ /^\d+$/
        age = input.to_i
        break
      else
        puts 'Invalid age. Please enter a valid number.'
      end
    end
    print 'Specialization: '
    spec = gets.chomp
    spec = 'General' if spec.strip.empty?
    teacher = Teacher.new(name, spec, age)
    @people << teacher
    puts 'Person created successfully'
  end

  def create_book
    print 'Title: '
    title = gets.chomp
    title = 'Unknown' if title.strip.empty?
    print 'Author: '
    author = gets.chomp
    author = 'Unknown' if author.strip.empty?
    book = Book.new(title, author)
    @books << book
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    if @people.empty?
      puts 'No people registered'
      return
    end
    puts 'Select a book by number:'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    book_index = nil
    loop do
      print 'Book number: '
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i.between?(0, @books.size - 1)
        book_index = input.to_i
        break
      else
        puts 'Invalid book number. Please try again.'
      end
    end
    puts 'Select a person by number:'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    person_index = nil
    loop do
      print 'Person number: '
      input = gets.chomp
      if input =~ /^\d+$/ && input.to_i.between?(0, @people.size - 1)
        person_index = input.to_i
        break
      else
        puts 'Invalid person number. Please try again.'
      end
    end
    print 'Date (YYYY-MM-DD): '
    date = gets.chomp
    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    if @people.empty?
      puts 'No people registered'
      return
    end
    print 'ID of person: '
    id_input = gets.chomp.to_i
    person = @people.detect { |p| p.id == id_input }
    if person
      if person.rentals.empty?
        puts 'No rentals found for this person'
      else
        person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
      end
    else
      puts 'Person not found'
    end
  end
end