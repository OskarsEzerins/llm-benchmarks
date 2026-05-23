class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_accessor :nameable

  def initialize(nameable)
    super()
    @nameable = nameable
  end

  def correct_name
    @nameable.correct_name
  end
end

class TrimmerDecorator < Decorator
  def correct_name
    trimmed = @nameable.correct_name
    trimmed.length > 10 ? trimmed[0..9] : trimmed
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

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
    stud.classroom = self unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(100..999)
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = age.to_i >= 0 ? age.to_i : 0
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    self.classroom = classroom if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
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
      @books.each do |bk|
        puts "title: #{bk.title}, author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp&.strip
    if choice == '1'
      create_student
    elsif choice == '2'
      create_teacher
    else
      puts 'Invalid selection. Person creation cancelled.'
    end
  end

  def create_student
    age = get_valid_integer('Age: ')
    name = get_non_empty_string('Name: ')
    perm = get_parent_permission('Parent permission? [Y/N]: ')
    stu = Student.new(age, nil, name, parent_permission: perm)
    @people << stu
    puts 'Student registered successfully'
  end

  def create_teacher
    age = get_valid_integer('Age: ')
    name = get_non_empty_string('Name: ')
    spec = get_non_empty_string('Specialization: ')
    t = Teacher.new(age, spec, name)
    @people << t
    puts 'Teacher registered successfully'
  end

  def create_book
    title = get_non_empty_string('Title: ')
    author = get_non_empty_string('Author: ')
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books registered'
      return
    end

    if @people.empty?
      puts 'No people registered'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = -1
    loop do
      bi = get_valid_integer('Book index: ')
      break if bi >= 0 && bi < @books.length
      puts 'Index out of bounds. Please try again.'
    end

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = -1
    loop do
      pi = get_valid_integer('Person index: ')
      break if pi >= 0 && pi < @people.length
      puts 'Index out of bounds. Please try again.'
    end

    print 'Date (YYYY-MM-DD): '
    dt = gets&.chomp&.strip
    dt = '2023-01-01' if dt.nil? || dt.empty?

    Rental.new(dt, @books[bi], @people[pi])
    puts 'Rental registered successfully'
  end

  def list_rentals
    if @people.empty?
      puts 'No one registered yet'
      return
    end

    pid = get_valid_integer('ID of person: ')
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj
      puts 'Rentals:'
      p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    else
      puts 'No person registered with that ID'
    end
  end

  private

  def get_non_empty_string(prompt)
    loop do
      print prompt
      input = gets&.chomp&.strip
      return input unless input.nil? || input.empty?
      puts 'Value cannot be empty. Please try again'
    end
  end

  def get_valid_integer(prompt)
    loop do
      print prompt
      input = gets&.chomp&.strip
      if input =~ /^\d+$/
        val = input.to_i
        return val if val >= 0
      end
      puts 'Value must be a positive integer. Please try again'
    end
  end

  def get_parent_permission(prompt)
    loop do
      print prompt
      input = gets&.chomp&.strip&.upcase
      return true if input == 'Y'
      return false if input == 'N'
      puts 'Invalid input. Please choose Y or N'
    end
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end