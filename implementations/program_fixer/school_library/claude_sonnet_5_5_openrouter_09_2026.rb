require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} must implement correct_name"
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
    super.to_s[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
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
  attr_accessor :name, :age, :rentals
  attr_reader :id, :parent_permission

  @@next_id = 0

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    super()
    @@next_id += 1
    @id = @@next_id
    @name = name.nil? || name.to_s.strip.empty? ? 'Unknown' : name.to_s
    @age = age.to_i
    @parent_permission = normalize_permission(parent_permission)
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

  def normalize_permission(value)
    if value.is_a?(String)
      value.strip.upcase.start_with?('Y') || value.strip.downcase == 'true'
    else
      value ? true : false
    end
  end

  def of_age?
    @age >= 18
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name, parent_permission: true)
    super(name, age, parent_permission: parent_permission)
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

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(name, age, parent_permission: parent_permission)
    @specialization = specialization
  end

  def can_use_services?
    true
  end
end

class App
  attr_reader :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' if @people.empty?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = read_input
    case choice
    when '1' then create_student
    when '2' then create_teacher
    else puts 'Invalid option'
    end
  end

  def create_student
    print 'Name: '
    nm = read_input
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_age(read_input)
    return puts('Invalid age') if ag.nil?

    print 'Parent permission? [Y/N] '
    perm = read_input.upcase
    return puts('Invalid parent permission response') unless %w[Y N].include?(perm)

    stu = Student.new(ag, nil, nm, parent_permission: perm == 'Y')
    @people << stu
    puts 'Student created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm = read_input
    nm = 'Unknown' if nm.empty?
    print 'Age: '
    ag = parse_age(read_input)
    return puts('Invalid age') if ag.nil?

    print 'Specialization: '
    spec = read_input
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
    t
  end

  def create_book
    print 'Title: '
    t = read_input
    print 'Author: '
    a = read_input
    return puts('Title and author cannot be empty') if t.empty? || a.empty?

    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    return puts('No books available') if @books.empty?
    return puts('No one has registered') if @people.empty?

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = Integer(read_input, exception: false)
    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = Integer(read_input, exception: false)

    return puts('Invalid selection') if bi.nil? || pi.nil? || !valid_indices?(pi, bi)

    rental = Rental.new(Date.today.to_s, @books[bi], @people[pi])
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid = Integer(read_input, exception: false)
    return puts('Invalid ID') if pid.nil?

    p_obj = @people.detect { |pr| pr.id == pid }
    return puts('Person not found') if p_obj.nil?

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def read_input
    line = gets
    line.nil? ? '' : line.to_s.chomp.strip
  end

  def parse_age(str)
    age = Integer(str, exception: false)
    return nil if age.nil? || age.negative?

    age
  end

  def valid_indices?(p_i, b_i)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end