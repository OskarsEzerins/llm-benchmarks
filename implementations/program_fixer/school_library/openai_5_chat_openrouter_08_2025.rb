class App
  def initialize
    @books = []
    @people = []
    @rentals = []
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
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person
    print 'Do you want to create a Student (1) or Teacher (2)? [Input number]: '
    choice = gets.chomp
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
    nm = gets.chomp.strip
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? [Y/N]: '
    perm_input = gets.chomp.strip.upcase
    until %w[Y N].include?(perm_input)
      print 'Please enter Y or N: '
      perm_input = gets.chomp.strip.upcase
    end
    perm = perm_input == 'Y'
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp.strip
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '
    spec = gets.chomp.strip
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    t = gets.chomp.strip
    print 'Author: '
    a = gets.chomp.strip
    @books << Book.new(t, a)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Cannot create rental without books and people'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) #{b.title}" }
    bi = gets.chomp.to_i
    if bi.negative? || bi >= @books.size
      puts 'Invalid book selection'
      return
    end

    puts 'Select a person from the following list by number'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}" }
    pi = gets.chomp.to_i
    if pi.negative? || pi >= @people.size
      puts 'Invalid person selection'
      return
    end

    print 'Date (YYYY-MM-DD): '
    date = gets.chomp.strip
    rental = Rental.new(date, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    person_rentals = @rentals.select { |r| r.person.id == pid }
    if person_rentals.empty?
      puts 'No rentals found for this person'
    else
      person_rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
    end
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
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
    name = super
    name.length > 10 ? name[0..9] : name
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.capitalize
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

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name.nil? || name.strip.empty? ? 'Unknown' : name
    @age = age.to_i
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
    super(age, name, parent_permission: parent_permission)
    @classroom = classroom
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

  def initialize(age, specialization, name)
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end