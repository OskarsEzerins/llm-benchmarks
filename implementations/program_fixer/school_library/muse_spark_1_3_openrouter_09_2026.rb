require 'date'

class Nameable
  def correct_name
    raise NotImplementedError, 'Subclasses must implement correct_name'
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
    super.to_s[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    super.to_s.capitalize
  end
end

class Person < Nameable
  attr_reader :id, :parent_permission
  attr_accessor :name, :age, :rentals

  def initialize(age = 0, name = 'Unknown', parent_permission: true)
    super()
    @id = rand(1..1000)
    @name = sanitize_name(name)
    @age = sanitize_age(age)
    @parent_permission = parent_permission.nil? ? true : !!parent_permission
    @parent_permission = true if parent_permission.nil?
    if [true, false].include?(parent_permission)
      @parent_permission = parent_permission
    else
      @parent_permission = !!parent_permission
      @parent_permission = true if parent_permission.nil?
    end
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

  def sanitize_name(name)
    return 'Unknown' if name.nil? || name.to_s.strip.empty?

    name.to_s
  end

  def sanitize_age(age)
    int_age = begin
      Integer(age)
    rescue StandardError
      begin
        Integer(age.to_i)
      rescue StandardError
        0
      end
    end
    int_age = 0 if int_age.nil?
    int_age = 0 if int_age.negative?
    int_age
  end
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
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

    room.students.push(self) unless room.students.include?(self)
  end

  def assign_classroom(room)
    self.classroom = room
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown', parent_permission: true)
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization.to_s
  end

  def can_use_services?
    true
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label = label
    @students = []
  end

  def add_student(student)
    @students = [] if @students.nil?
    @students << student unless @students.include?(student)
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
    @book.rentals << self if @book && @book.rentals
    @person.rentals << self if @person && @person.rentals
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
    if @books.nil? || @books.empty?
      puts 'No books available'
    else
      @books.each do |bk|
        puts "Title: #{bk.title}, Author: #{bk.author}"
      end
    end
  end

  def list_people
    if @people.nil? || @people.empty?
      puts 'No one has registered'
    else
      @people.each do |human|
        puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
      end
    end
  end

  def create_person(choice_input = nil)
    print 'Do you want to create a student (2) or a teacher (1)? '
    choice = choice_input || gets&.chomp
    choice = choice.to_s.strip
    case choice
    when '1'
      create_teacher
    when '2'
      create_student
    else
      puts 'Invalid selection'
      nil
    end
  end

  def create_student(name_input = nil, age_input = nil, permission_input = nil, classroom_input = nil)
    print 'Name: '
    raw_name = name_input.nil? ? gets&.chomp : name_input
    nm = (raw_name.nil? || raw_name.to_s.strip.empty?) ? 'Unknown' : raw_name.to_s.strip

    print 'Age: '
    raw_age = age_input.nil? ? gets&.chomp : age_input
    ag = begin
      Integer(raw_age)
    rescue StandardError
      begin
        raw_age.to_i
      rescue StandardError
        0
      end
    end
    ag = 0 if ag.nil? || !ag.is_a?(Integer) || ag.negative?

    print 'Has parent permission? [Y/N]: '
    raw_perm = permission_input.nil? ? gets&.chomp : permission_input
    perm = raw_perm.to_s.strip.upcase
    parent_permission = if %w[Y N].include?(perm)
                          perm == 'Y'
                        elsif [true, false].include?(raw_perm)
                          raw_perm
                        else
                          perm == 'Y'
                        end

    stu = Student.new(ag, classroom_input, nm, parent_permission: parent_permission)
    @people << stu
    puts 'Person created successfully'
    stu
  rescue StandardError
    fallback = Student.new(0, nil, 'Unknown', parent_permission: true)
    @people << fallback
    fallback
  end

  def create_teacher(name_input = nil, age_input = nil, spec_input = nil)
    print 'Name: '
    raw_name = name_input.nil? ? gets&.chomp : name_input
    nm = (raw_name.nil? || raw_name.to_s.strip.empty?) ? 'Unknown' : raw_name.to_s.strip

    print 'Age: '
    raw_age = age_input.nil? ? gets&.chomp : age_input
    ag = begin
      Integer(raw_age)
    rescue StandardError
      begin
        raw_age.to_i
      rescue StandardError
        0
      end
    end
    ag = 0 if ag.nil? || !ag.is_a?(Integer) || ag.negative?

    print 'Specialization: '
    spec = spec_input.nil? ? gets&.chomp : spec_input
    spec = '' if spec.nil?
    spec = spec.to_s

    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  rescue StandardError
    fallback = Teacher.new(0, '', 'Unknown')
    @people << fallback
    fallback
  end

  def create_book(title_input = nil, author_input = nil)
    print 'Title: '
    t = title_input.nil? ? gets&.chomp : title_input
    t = '' if t.nil?
    print 'Author: '
    a = author_input.nil? ? gets&.chomp : author_input
    a = '' if a.nil?
    book = Book.new(t.to_s, a.to_s)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental(book_index_input = nil, person_index_input = nil, date_input = nil)
    if @books.empty? || @people.empty?
      puts 'No books or people available'
      return nil
    end
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi_raw = book_index_input.nil? ? gets&.chomp : book_index_input
    bi = bi_raw.to_i

    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi_raw = person_index_input.nil? ? gets&.chomp : person_index_input
    pi = pi_raw.to_i

    print 'Date: '
    d = date_input.nil? ? gets&.chomp : date_input
    d = Date.today.to_s if d.nil? || d.to_s.strip.empty?
    d = d.to_s

    unless valid_indices?(pi, bi)
      puts 'Invalid indices'
      return nil
    end

    rental = Rental.new(d, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  rescue StandardError
    puts 'Invalid indices'
    nil
  end

  def list_rentals(person_id_input = nil)
    print 'ID of person: '
    pid_raw = person_id_input.nil? ? gets&.chomp : person_id_input
    return puts 'Person not found' if pid_raw.nil?

    pid = pid_raw.to_s.strip.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return
    end
    if p_obj.rentals.nil? || p_obj.rentals.empty?
      puts 'No rentals found'
    else
      p_obj.rentals.each { |r| puts "Date: #{r.date}, Book: #{r.book.title} by #{r.book.author}" }
    end
  end

  private

  def valid_indices?(p_i, b_i)
    return false if p_i.nil? || b_i.nil?
    return false unless p_i.is_a?(Integer) && b_i.is_a?(Integer)

    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end