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
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    loop do
      print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
      choice = gets.chomp
      case choice
      when '1'
        return create_student
      when '2'
        return create_teacher
      else
        puts 'Invalid option. Please try again.'
      end
    end
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag = gets.chomp
    ag = ag.to_i
    while ag <= 0
      print 'Invalid age. Please enter a valid age: '
      ag = gets.chomp.to_i
    end

    print 'Has parent permission? [Y/N]: '
    perm = gets.chomp.upcase
    until perm == 'Y' || perm == 'N'
      print 'Invalid input. Has parent permission? [Y/N]: '
      perm = gets.chomp.upcase
    end
    parent_perm = perm == 'Y'

    stu = Student.new(ag, nil, nm, parent_permission: parent_perm)
    @people << stu
    puts 'Student created successfully'
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag = gets.chomp
    ag = ag.to_i
    while ag <= 0
      print 'Invalid age. Please enter a valid age: '
      ag = gets.chomp.to_i
    end

    print 'Specialization: '
    spec = gets.chomp
    spec = 'Unknown' if spec.nil? || spec.strip.empty?

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    t = 'Unknown' if t.nil? || t.strip.empty?

    print 'Author: '
    a = gets.chomp
    a = 'Unknown' if a.nil? || a.strip.empty?

    @books << Book.new(t, a)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'Cannot create rental. Make sure books and people exist.'
      return
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = gets.chomp.to_i
    until valid_book_index?(bi)
      print 'Invalid book index. Please try again: '
      bi = gets.chomp.to_i
    end

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets.chomp.to_i
    until valid_person_index?(pi)
      print 'Invalid person index. Please try again: '
      pi = gets.chomp.to_i
    end

    print 'Date: '
    date = gets.chomp
    date = 'Unknown' if date.nil? || date.strip.empty?

    Rental.new(date, @books[bi], @people[pi])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals found for this person'
      return
    end
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
  end

  private

  def valid_book_index?(b_i)
    b_i.is_a?(Integer) && b_i >= 0 && b_i < @books.length
  end

  def valid_person_index?(p_i)
    p_i.is_a?(Integer) && p_i >= 0 && p_i < @people.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
    @nameable.correct_name[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_reader :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self
    @person.rentals << self
  end
end

class Book
  attr_accessor :title, :author
  attr_reader :rentals

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
  attr_accessor :label
  attr_reader :students

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
  attr_accessor :name, :age, :rentals
  attr_reader :id

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = name
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

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    super(name, age.to_i, parent_permission: parent_permission)
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
  attr_reader :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(name, age.to_i, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end