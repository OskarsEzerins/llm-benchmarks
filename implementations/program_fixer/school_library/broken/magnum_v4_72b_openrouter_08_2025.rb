class App
  def initialize
    @books  = []
    @people = []
  end

  def list_books
    puts 'No books available' if @books&.empty?
    @books.each do |bk|
      puts "title: #{bk.title}, author: #{bk.author}"
    end
  end

  def list_people
    puts 'No one has registered' unless @people.any?
    @people.each do |human|
      puts "[#{human.class}] id: #{human.id}, Name: #{human.name}, Age: #{human.age}"
    end
  end

  def create_person
    print 'Student(1) or Teacher(2)? '
    choice = gets.chomp
    create_teacher if choice == '2'
    create_student if choice == '1'  
  end

  def create_student
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Parent permission? (Y/N) '
    perm = gets.chomp.downcase == 'y'
    stu = Student.new(ag, nil, nm, parent_permission: perm)
    @people << stu
  end

  def create_teacher
    print 'Name: '
    nm = gets.chomp
    print 'Age: '
    ag = gets.chomp.to_i
    print 'Specialization: '  
    spec = gets.chomp
    t = Teacher.new(nm, spec, ag)
    @people << t
  end

  def create_book
    print 'Title: '
    t = gets.chomp
    print 'Author: '
    a = gets.chomp
    @books << Book.new(t, a)
  end

  def create_rental
    return puts 'No books available' if @books.empty?
    return puts 'No people registered' if @people.empty?

    puts 'Select a book'
    @books.each_with_index { |b, i| puts "#{i}: #{b.title}" }
    bi = gets.chomp.to_i
    return puts 'Invalid book index' unless valid_index?(bi, @books.size)

    puts 'Select person'
    @people.each_with_index { |p, i| puts "#{i}: #{p.name}" }
    pi = gets.chomp.to_i
    return puts 'Invalid person index' unless valid_index?(pi, @people.size)

    Rental.new(Date.today, @books[bi], @people[pi])  
  end

  def list_rentals
    print 'ID of person: '
    pid = gets.chomp.to_i
    p_obj = @people.find { |pr| pr.id == pid }
    return puts 'Person not found' unless p_obj

    p_obj.rentals.each { |r| puts "#{r.date} - #{r.book.title}" }
  end

  private

  def valid_index?(index, size)
    index.between?(0, size - 1)
  end
end

class Nameable
  def correct_name
    nil
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
    super[0..9]
  end
end

class CapitalizeDecorator < Decorator
  def correct_name
    @nameable.correct_name.capitalize
  end
end

class Rental
  attr_accessor :date, :book, :person

  def initialize(date, book, person)
    @date   = date
    @book   = book
    @person = person
    book.rentals << self
    person.rentals << self
  end
end

class Book
  attr_accessor :title, :author, :rentals

  def initialize(title, author)
    @title    = title
    @author   = author
    @rentals  = []
  end

  def add_rental(person, date)
    Rental.new(date, self, person)
  end
end

class Classroom
  attr_accessor :label, :students

  def initialize(label)
    @label  = label
    @students = []
  end

  def add_student(student)
    students << student
    student.classroom = self
  end
end

class Person < Nameable
  attr_accessor :id, :name, :age, :rentals

  def initialize(name = 'Unknown', age = 0, parent_permission: true)
    @id = rand(1000)
    @name = name
    @age = age
    @parent_permission = parent_permission
    @rentals = []
  end

  def can_use_services?
    of_age? || parent_permission
  end

  def correct_name