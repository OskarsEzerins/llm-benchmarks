require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    super.to_s[0...10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && !(age.strip.match?(/\A-?\d+\z/)) &&
       (name.is_a?(Integer) || name.is_a?(Numeric) ||
        (name.is_a?(String) && name.strip.match?(/\A-?\d+\z/)))
      age, name = name, age
    end

    @id = rand(1..1000)

    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s

    begin
      @age = Integer(age)
    rescue StandardError
      @age = age.to_i rescue 0
    end
    @age = 0 if @age.nil? || @age.negative?

    @parent_permission = sanitize_permission(parent_permission)

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

  def sanitize_permission(value)
    return value if value == true || value == false

    if value.is_a?(String)
      s = value.strip.upcase
      return true if %w[Y YES TRUE T 1].include?(s)
      return false if %w[N NO FALSE F 0].include?(s)
      return true
    end
    value ? true : false
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age = 0, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?
    return unless room.respond_to?(:students)
    return if room.students.include?(self)

    room.students << self
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && !age.strip.match?(/\A-?\d+\z/) &&
       (name.is_a?(Integer) || name.is_a?(Numeric) ||
        (name.is_a?(String) && name.strip.match?(/\A-?\d+\z/)))
      actual_name = age
      actual_age = name
      age = actual_age
      name = actual_name
    end
    super(age, name, parent_permission: parent_permission)
    @specialization = (specialization.nil? || specialization.to_s.strip.empty?) ? 'Unknown' : specialization.to_s
  end

  def can_use_services?
    true
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label.to_s
    @students = []
  end

  def add_student(student)
    return if @students.include?(student)

    @students << student
    student.classroom = self unless student.classroom == self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.to_s
    @author = author.to_s
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    @book.rentals << self if @book && @book.respond_to?(:rentals) && !@book.rentals.include?(self)
    @person.rentals << self if @person && @person.respond_to?(:rentals) && !@person.rentals.include?(self)
  end
end

class App
  attr_accessor :books, :people

  def initialize
    @books = []
    @people = []
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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = gets&.chomp
    case choice
    when '1', '3'
      create_student
    when '2'
      create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag_input = gets&.chomp
    ag = sanitize_age(ag_input)

    print 'Has parent permission? [Y/N]: '
    perm_input = gets&.chomp
    perm = sanitize_permission_input(perm_input)

    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?

    print 'Age: '
    ag_input = gets&.chomp
    ag = sanitize_age(ag_input)

    print 'Specialization: '
    spec = gets&.chomp
    spec = 'Unknown' if spec.nil? || spec.strip.empty?

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    t = gets&.chomp
    t = 'Unknown' if t.nil? || t.strip.empty?

    print 'Author: '
    a = gets&.chomp
    a = 'Unknown' if a.nil? || a.strip.empty?

    b = Book.new(t, a)
    @books << b
    puts 'Book created successfully'
    b
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi_input = gets&.chomp
    bi = bi_input.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi_input = gets&.chomp
    pi = pi_input.to_i

    print 'Date: '
    date_input = gets&.chomp
    date_input = Date.today.to_s if date_input.nil? || date_input.strip.empty?

    unless valid_indices?(pi, bi)
      puts 'Invalid indices'
      return nil
    end

    rental = Rental.new(date_input, @books[bi], @people[pi])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets&.chomp
    pid = pid_input.to_i

    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    if p_obj.rentals.empty?
      puts 'No rentals found'
    else
      p_obj.rentals.each do |r|
        puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}"
      end
    end
  end

  def valid_indices?(p_i, b_i)
    return false unless p_i.is_a?(Integer) && b_i.is_a?(Integer)

    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end

  private

  def sanitize_age(value)
    age = begin
      Integer(value)
    rescue StandardError
      value.to_i rescue 0
    end
    age = 0 if age.nil? || age.negative?
    age
  end

  def sanitize_permission_input(value)
    return true if value.nil? || value.strip.empty?

    s = value.strip.upcase
    return true if s == 'Y'
    return false if s == 'N'

    true
  end
end