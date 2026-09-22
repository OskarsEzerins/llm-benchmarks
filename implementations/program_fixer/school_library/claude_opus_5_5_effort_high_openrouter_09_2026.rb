require 'date'

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
    name = super.to_s
    name.length > 10 ? name[0..9] : name
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
    book.rentals << self if book.respond_to?(:rentals) && !book.rentals.include?(self)
    person.rentals << self if person.respond_to?(:rentals) && !person.rentals.include?(self)
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

  def add_student(student)
    return if student.nil?

    @students << student unless @students.include?(student)
    student.classroom = self unless student.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals
  attr_reader :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    age, name = name, age if swap_arguments?(age, name)
    @id = rand(1..1000)
    @name = normalize_name(name)
    @age = normalize_age(age)
    @parent_permission = normalize_permission(parent_permission)
    @rentals = []
  end

  def parent_permission=(value)
    @parent_permission = normalize_permission(value)
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
    @age.to_i >= 18
  end

  def numeric_value?(value)
    return true if value.is_a?(Numeric)

    value.is_a?(String) && value.strip.match?(/\A-?\d+(\.\d+)?\z/)
  end

  def swap_arguments?(age, name)
    age.is_a?(String) && !age.strip.empty? && !numeric_value?(age) &&
      (name.nil? || name == 'Unknown' || numeric_value?(name))
  end

  def normalize_name(name)
    str = name.to_s.strip
    str.empty? ? 'Unknown' : str
  end

  def normalize_age(age)
    value = case age
            when Integer then age
            when Float then age.to_i
            else
              begin
                Integer(age.to_s.strip, 10)
              rescue ArgumentError, TypeError
                0
              end
            end
    value.negative? ? 0 : value
  end

  def normalize_permission(value)
    case value
    when true then true
    when false, nil then false
    when String then %w[y yes true].include?(value.strip.downcase)
    else !!value
    end
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
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

  def initialize(age, specialization, name = 'Unknown')
    super(age, name, parent_permission: true)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class App
  attr_reader :books, :people, :rentals

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
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    choice = read_input
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else
      puts 'Invalid option'
      nil
    end
  end

  def create_student
    print 'Name: '
    nm = read_input
    print 'Age: '
    ag = parse_age(read_input)
    print 'Parent permission? [Y/N]: '
    perm = read_input.upcase
    unless %w[Y N].include?(perm)
      puts 'Invalid answer, parent permission set to N'
      perm = 'N'
    end
    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = read_input
    print 'Age: '
    ag = parse_age(read_input)
    print 'Specialization: '
    spec = read_input
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    t = read_input
    print 'Author: '
    a = read_input
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'You need at least one book and one person to create a rental'
      return nil
    end

    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: \"#{b.title}\", Author: #{b.author}" }
    bi = parse_index(read_input)

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index do |p, i|
      puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}"
    end
    pi = parse_index(read_input)

    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return nil
    end

    print 'Date: '
    date_input = read_input
    date = date_input.empty? ? Date.today.to_s : date_input

    rental = Rental.new(date, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    input = read_input
    pid = begin
      Integer(input, 10)
    rescue ArgumentError, TypeError
      nil
    end

    p_obj = pid.nil? ? nil : @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end

    if p_obj.rentals.empty?
      puts 'No rentals found'
      return
    end

    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end

  private

  def read_input
    input = gets
    input.nil? ? '' : input.to_s.chomp.strip
  end

  def parse_age(input)
    value = Integer(input.to_s.strip, 10)
    value.negative? ? 0 : value
  rescue ArgumentError, TypeError
    0
  end

  def parse_index(input)
    Integer(input.to_s.strip, 10)
  rescue ArgumentError, TypeError
    -1
  end

  def valid_indices?(p_i, b_i)
    p_i.is_a?(Integer) && b_i.is_a?(Integer) &&
      p_i >= 0 && p_i < @people.length &&
      b_i >= 0 && b_i < @books.length
  end
end