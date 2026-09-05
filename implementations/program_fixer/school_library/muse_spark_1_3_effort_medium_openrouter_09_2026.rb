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
    name = super.to_s
    name.length > 10 ? name[0...10] : name
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
    super()
    actual_age = age
    actual_name = name
    if age.is_a?(String) && name.is_a?(Integer)
      actual_name = age
      actual_age = name
    elsif age.is_a?(String) && name.to_s.strip.empty?
      actual_name = age
      actual_age = 0
    end
    @id = rand(1..1000)
    if actual_name.nil? || actual_name.to_s.strip.empty?
      @name = 'Unknown'
    else
      @name = actual_name.to_s
    end
    begin
      parsed = Integer(actual_age)
    rescue StandardError
      begin
        parsed = actual_age.to_i
      rescue StandardError
        parsed = 0
      end
    end
    parsed = 0 if parsed.nil?
    parsed = 0 if parsed.negative?
    @age = parsed
    @parent_permission = parent_permission == true
    @parent_permission = true if parent_permission.nil?
    if parent_permission.is_a?(String)
      @parent_permission = %w[y yes true 1].include?(parent_permission.strip.downcase)
    else
      @parent_permission = !!parent_permission
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
end

class Student < Person
  attr_reader :classroom

  def initialize(age, classroom, name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && name.is_a?(Integer)
      tmp = age
      age = name
      name = tmp
    end
    super(age, name, parent_permission: parent_permission)
    @classroom = nil
    self.classroom = classroom unless classroom.nil?
  end

  def play_hooky
    '¯\\_(ツ)_/¯'
  end

  def classroom=(room)
    @classroom = room
    return if room.nil?
    room.students << self unless room.students.include?(self)
  end
end

class Teacher < Person
  attr_accessor :specialization

  def initialize(age = 0, specialization = 'Unknown', name = 'Unknown', parent_permission: true)
    if age.is_a?(String) && name.is_a?(Integer)
      tmp_name = age
      tmp_age = name
      age = tmp_age
      name = tmp_name
    end
    super(age, name, parent_permission: parent_permission)
    @specialization = specialization.nil? || specialization.to_s.strip.empty? ? 'Unknown' : specialization.to_s
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

  def add_student(stud)
    @students << stud unless @students.include?(stud)
    stud.classroom = self if stud.classroom != self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title = title.nil? || title.to_s.strip.empty? ? 'Unknown' : title.to_s
    @author = author.nil? || author.to_s.strip.empty? ? 'Unknown' : author.to_s
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
    @book.rentals << self if @book && @book.rentals.is_a?(Array)
    @person.rentals << self if @person && @person.rentals.is_a?(Array)
  end
end

class App
  attr_accessor :books, :people, :rentals

  def initialize
    @books = []
    @people = []
    @rentals = []
  end

  def list_books
    if @books.nil? || @books.empty?
      puts 'No books available'
      return
    end
    @books.each do |bk|
      puts "Title: #{bk.title}, Author: #{bk.author}"
    end
  end

  def list_people
    if @people.nil? || @people.empty?
      puts 'No one has registered'
      return
    end
    @people.each do |human|
      puts "[#{human.class}] ID: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Do you want to create a student (1) or a teacher (2)? [Input the number]: '
    input = gets
    choice = input ? input.chomp.strip : ''
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
    nm_input = gets
    nm = nm_input ? nm_input.chomp : nil
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = gets
    ag_str = ag_input ? ag_input.chomp : '0'
    begin
      ag = Integer(ag_str)
    rescue StandardError
      ag = ag_str.to_i
    end
    ag = 0 if ag.negative?
    print 'Has parent permission? [Y/N]: '
    perm_input = gets
    perm_str = perm_input ? perm_input.chomp.strip.upcase : ''
    perm = case perm_str
           when 'Y' then true
           when 'N' then false
           else true
           end
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
    puts 'Person created successfully'
    stu
  end

  def create_teacher
    print 'Name: '
    nm_input = gets
    nm = nm_input ? nm_input.chomp : nil
    nm = 'Unknown' if nm.nil? || nm.strip.empty?
    print 'Age: '
    ag_input = gets
    ag_str = ag_input ? ag_input.chomp : '0'
    begin
      ag = Integer(ag_str)
    rescue StandardError
      ag = ag_str.to_i
    end
    ag = 0 if ag.negative?
    print 'Specialization: '
    spec_input = gets
    spec = spec_input ? spec_input.chomp : nil
    spec = 'Unknown' if spec.nil? || spec.strip.empty?
    t = Teacher.new(ag, spec, nm)
    @people << t
    puts 'Person created successfully'
    t
  end

  def create_book
    print 'Title: '
    t_input = gets
    t = t_input ? t_input.chomp : nil
    t = 'Unknown' if t.nil? || t.strip.empty?
    print 'Author: '
    a_input = gets
    a = a_input ? a_input.chomp : nil
    a = 'Unknown' if a.nil? || a.strip.empty?
    book = Book.new(t, a)
    @books << book
    puts 'Book created successfully'
    book
  end

  def create_rental
    if @books.empty?
      puts 'No books available'
      return nil
    end
    if @people.empty?
      puts 'No one has registered'
      return nil
    end
    puts 'Select a book from the following list by number'
    @books.each_with_index { |b, i| puts "#{i}) Title: #{b.title}, Author: #{b.author}" }
    bi_input = gets
    return nil if bi_input.nil?
    bi = bi_input.chomp.to_i
    puts 'Select a person from the following list by number (not id)'
    @people.each_with_index { |p, i| puts "#{i}) [#{p.class}] Name: #{p.name}, ID: #{p.id}, Age: #{p.age}" }
    pi_input = gets
    return nil if pi_input.nil?
    pi = pi_input.chomp.to_i
    print 'Date: '
    date_input = gets
    date = date_input ? date_input.chomp : Date.today.to_s
    date = Date.today.to_s if date.strip.empty?
    unless valid_indices?(pi, bi)
      puts 'Invalid selection'
      return nil
    end
    rental = Rental.new(date, @books[bi], @people[pi])
    @rentals << rental
    puts 'Rental created successfully'
    rental
  end

  def list_rentals
    print 'ID of person: '
    pid_input = gets
    return nil if pid_input.nil?
    pid = pid_input.chomp.to_i
    p_obj = @people.detect { |pr| pr.id == pid }
    if p_obj.nil?
      puts 'Person not found'
      return nil
    end
    if p_obj.rentals.empty?
      puts 'No rentals found'
      return nil
    end
    p_obj.rentals.each { |r| puts "Date: #{r.date}, Book \"#{r.book.title}\" by #{r.book.author}" }
  end

  def valid_indices?(p_i, b_i)
    return false if @people.nil? || @books.nil?
    return false unless p_i.is_a?(Integer) && b_i.is_a?(Integer)
    p_i >= 0 && p_i < @people.length && b_i >= 0 && b_i < @books.length
  end
end