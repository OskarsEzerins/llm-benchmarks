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
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    puts 'Do you want to create a student (1) or a teacher (2)? [Input the number]:'
    choice = gets&.chomp
    case choice
    when '1'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid selection'
    end
  end

  def create_student
    print 'Name: '
    nm = (gets&.chomp).to_s.strip
    nm = 'Unknown' if nm.empty?

    print 'Age: '
    ag_input = gets&.chomp
    ag = ag_input.to_i
    ag = 0 if ag.negative?

    perm = ask_yes_no('Parent permission? [Y/N]: ')
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    nm = (gets&.chomp).to_s.strip
    nm = 'Unknown' if nm.empty?

    print 'Age: '
    ag_input = gets&.chomp
    ag = ag_input.to_i
    ag = 0 if ag.negative?

    print 'Specialization: '
    spec = (gets&.chomp).to_s.strip
    spec = 'General' if spec.empty?

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    t = (gets&.chomp).to_s.strip
    t = 'Untitled' if t.empty?

    print 'Author: '
    a = (gets&.chomp).to_s.strip
    a = 'Unknown' if a.empty?

    @books << Book.new(t, a)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return
    end
    if @people.empty?
      puts 'No people available'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    print 'Book number: '
    bi = gets&.chomp&.to_i
    unless bi.is_a?(Integer) && bi >= 0 && bi < @books.length
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    print 'Person number: '
    pi = gets&.chomp&.to_i
    unless pi.is_a?(Integer) && pi >= 0 && pi < @people.length
      puts 'Invalid person selection'
      return
    end

    print 'Date [YYYY-MM-DD]: '
    date_input = (gets&.chomp).to_s.strip
    date_input = Date.today.to_s if date_input.empty?

    rental = Rental.new(date_input, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets&.chomp
    pid = pid_input.to_i
    person = @people.find { |p| p.id == pid }
    if person.nil?
      puts 'Person not found'
      return
    end
    if person.rentals.empty?
      puts 'No rentals found for this person'
      return
    end
    person.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def ask_yes_no(prompt)
    print prompt
    answer = (gets&.chomp).to_s.strip.upcase
    return true if answer == 'Y'
    return false if answer == 'N'

    # Handle invalid input gracefully by defaulting to false
    false
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
    super.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
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
  attr_reader :title, :author, :rentals

  def initialize(title, author)
    @title = (title || 'Untitled').to_s
    @author = (author || 'Unknown').to_s
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
    return if stud.nil?

    @students << stud unless @students.include?(stud)
    stud.assign_classroom(self)
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1..10_000)
    @name = (name || 'Unknown').to_s
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
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    assign_classroom(classroom) if classroom
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def assign_classroom(room)
    return if room.nil?

    @classroom = room
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  # Expected usage: Teacher.new(age, specialization, name)
  def initialize(age, specialization, name = 'Unknown')
    super(name, age, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end