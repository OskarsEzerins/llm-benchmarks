require 'date'

class App
  attr_accessor :books, :people

  def initialize
    @books = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books.nil? || @books.empty?
    return if @books.nil?
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (2) or a teacher (1)? Input the number: '
    choice = gets&.chomp&.strip
    case choice
    when '1'
      create_teacher
    when '2', '3'
      create_student
    else
      puts 'Invalid option. Please choose 1 for Teacher or 2 for Student.'
      nil
    end
  end

  def create_student
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = gets&.chomp
    ag = begin
      Integer(ag_input)
    rescue StandardError
      (ag_input.to_i rescue 0)
    end
    ag = 0 if ag.nil? || ag < 0
    print 'Has parent permission? [Y/N]: '
    perm_input = gets&.chomp
    perm = parse_permission(perm_input)
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Student created successfully'
    stu
  rescue StandardError
    nil
  end

  def create_teacher
    print 'Name: '
    nm = gets&.chomp
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = gets&.chomp
    ag = begin
      Integer(ag_input)
    rescue StandardError
      (ag_input.to_i rescue 0)
    end
    ag = 0 if ag.nil? || ag < 0
    print 'Specialization: '
    spec = gets&.chomp
    spec = 'Unknown' if spec.nil? || spec.strip.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Teacher created successfully'
    t
  rescue StandardError
    nil
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
  rescue StandardError
    nil
  end

  def create_rental
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi = gets&.chomp.to_i
    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi = gets&.chomp.to_i
    print 'Date: '
    date_input = gets&.chomp
    date_input = Date.today.to_s if date_input.nil? || date_input.strip.empty?
    unless valid_indices?(pi, bi)
      puts 'Invalid index'
      return nil
    end
    Rental.new(date_input, @books[bi], @people[pi])
  rescue StandardError
    nil
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets&.chomp
    return puts 'Person not found' if pid_input.nil?
    pid = pid_input.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return nil
    end
    puts 'Rentals:'
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
  rescue StandardError
    nil
  end

  private

  def parse_permission(input)
    return false if input.nil?
    s = input.strip.upcase
    return true if s == 'Y'
    return false if s == 'N'
    false
  end

  def valid_indices?(p_i, b_i)
    return false if p_i.nil? || b_i.nil?
    return false unless p_i.is_a?(Integer) && b_i.is_a?(Integer)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
  end
end

class Decorator < Nameable
  attr_reader :nameable

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
    name = name.to_s
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
    @book.rentals << self if @book && @book.rentals.is_a?(Array)
    @person.rentals << self if @person && @person.rentals.is_a?(Array)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.nil? || title.to_s.strip.empty? ? 'Unknown' : title
    @author = author.nil? || author.to_s.strip.empty? ? 'Unknown' : author
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
    stud.classroom = self unless stud.classroom == self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && (name.is_a?(Integer) || name.to_s =~ /\A-?\d+\z/)
      age, name = name, age
    end
    @id = rand(1..1000)
    @name = (name.nil? || name.to_s.strip.empty?) ? 'Unknown' : name.to_s
    @age = begin
      Integer(age)
    rescue StandardError
      (age.to_i rescue 0)
    end
    @age = 0 if @age.nil? || @age < 0
    @parent_permission = parent_permission.nil? ? false : !!parent_permission
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

  def initialize(age, classroom = nil, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '╰(°▽°)╯'
  end

  def classroom=(room)
    return if room.nil?
    @classroom = room
    room.students << self if room.students.is_a?(Array) && !room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && name.is_a?(Integer)
      age, name = name, age
    elsif age.is_a?(String) && specialization.is_a?(String) && name.is_a?(Integer)
      age, name = name, age
    end
    if age.is_a?(String) && specialization.is_a?(String) && name.is_a?(String)
      begin
        Integer(age)
      rescue StandardError
        age, specialization, name = name, age, specialization
      end
    end
    super(age, name, parent_permission: parent_permission)
    @specialization = (specialization.nil? || specialization.to_s.strip.empty?) ? 'Unknown' : specialization.to_s
  end

  def can_use_services?
    true
  end
end