class Nameable
  def correct_name
    raise NotImplementedError, "#{self.class} has not implemented method 'correct_name'"
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
    name = super
    return '' if name.nil?

    name[0, 10]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    name = super
    return '' if name.nil?

    name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date = date
    @book = book
    @person = person
    book.rentals << self unless book.nil? || book.rentals.nil? || book.rentals.include?(self)
    person.rentals << self unless person.nil? || person.rentals.nil? || person.rentals.include?(self)
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = normalize_text(title)
    @author = normalize_text(author)
    @rentals = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end

  private

  def normalize_text(value)
    text = value.to_s.strip
    text.empty? ? 'Unknown' : text
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
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals, :parent_permission

  def initialize(age, name = 'Unknown', parent_permission: true)
    super()
    @id = Random.rand(1..1000)
    @name = normalize_name(name)
    @age = normalize_age(age)
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

  def of_age?
    @age >= 18
  end

  def normalize_name(name)
    cleaned = name.to_s.strip
    cleaned.empty? ? 'Unknown' : cleaned
  end

  def normalize_age(age)
    return age if age.is_a?(Integer) && age >= 0

    str = age.to_s.strip
    return 0 unless str.match?(/\A\d+\z/)

    str.to_i
  end

  def normalize_permission(permission)
    return permission if permission == true || permission == false

    %w[y yes true].include?(permission.to_s.strip.downcase)
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
    @classroom = room
    return if room.nil?
    return if room.students.nil?

    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age, specialization, name = 'Unknown')
    super(age, name)
    @specialization = specialization.to_s.strip
    @specialization = 'Unknown' if @specialization.empty?
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
      return
    end

    @books.each do |book|
      puts "Title: #{book.title}, Author: #{book.author}"
    end
  end

  def list_people
    if @people.empty?
      puts 'No one has registered'
      return
    end

    @people.each do |person|
      puts "[#{person.class}] id: #{person.id}, Name: #{person.name}, Age: #{person.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = read_line
    return if choice.nil?

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
    name = read_name
    return if name.nil?

    age = read_age
    return if age.nil?

    permission = read_permission
    return if permission.nil?

    student = Student.new(age, nil, name, parent_permission: permission)
    @people << student
    puts 'Student created successfully'
  end

  def create_teacher
    name = read_name
    return if name.nil?

    age = read_age
    return if age.nil?

    print 'Specialization: '
    specialization = read_line
    return if specialization.nil?

    specialization = 'Unknown' if specialization.empty?
    teacher = Teacher.new(age, specialization, name)
    @people << teacher
    puts 'Teacher created successfully'
  end

  def create_book
    print 'Title: '
    title = read_line
    return if title.nil?

    title = 'Unknown' if title.empty?

    print 'Author: '
    author = read_line
    return if author.nil?

    author = 'Unknown' if author.empty?
    @books << Book.new(title, author)
    puts 'Book created successfully'
  end

  def create_rental
    if @books.empty? || @people.empty?
      puts 'No books or people available to create a rental'
      return
    end

    puts 'Select a book'
    @books.each_with_index { |book, index| puts "#{index}: #{book.title}" }
    book_index = read_index(@books.length)
    return if book_index.nil?

    puts 'Select person'
    @people.each_with_index { |person, index| puts "#{index}: #{person.name}" }
    person_index = read_index(@people.length)
    return if person_index.nil?

    unless valid_indices?(person_index, book_index)
      puts 'Invalid selection'
      return
    end

    date = Time.now.strftime('%Y-%m-%d')
    Rental.new(date, @books[book_index], @people[person_index])
    puts 'Rental created successfully'
  end

  def list_rentals
    print 'ID of person: '
    raw_id = read_line
    return if raw_id.nil?

    unless raw_id.match?(/\A\d+\z/)
      puts 'Invalid ID'
      return
    end

    person = @people.find { |pr| pr.id == raw_id.to_i }
    if person.nil?
      puts 'Person not found'
      return
    end

    if person.rentals.nil? || person.rentals.empty?
      puts 'No rentals found'
      return
    end

    person.rentals.each { |rental| puts "#{rental.date} - #{rental.book.title}" }
  end

  private

  def read_line
    input = gets
    return nil if input.nil?

    input.chomp.strip
  end

  def read_name
    print 'Name: '
    name = read_line
    return nil if name.nil?

    name.empty? ? 'Unknown' : name
  end

  def read_age
    print 'Age: '
    raw = read_line
    return nil if raw.nil?

    unless raw.match?(/\A\d+\z/)
      puts 'Invalid age'
      return nil
    end

    age = raw.to_i
    if age.negative?
      puts 'Invalid age'
      return nil
    end

    age
  end

  def read_permission
    print 'Parent permission? [Y/N]: '
    raw = read_line
    return nil if raw.nil?

    case raw.upcase
    when 'Y'
      true
    when 'N'
      false
    else
      puts 'Invalid permission response'
      nil
    end
  end

  def read_index(length)
    raw = read_line
    return nil if raw.nil?

    unless raw.match?(/\A\d+\z/)
      puts 'Invalid selection'
      return nil
    end

    index = raw.to_i
    if index.negative? || index >= length
      puts 'Invalid selection'
      return nil
    end

    index
  end

  def valid_indices?(person_index, book_index)
    person_index.is_a?(Integer) && book_index.is_a?(Integer) &&
      person_index >= 0 && person_index < @people.length &&
      book_index >= 0 && book_index < @books.length
  end
end