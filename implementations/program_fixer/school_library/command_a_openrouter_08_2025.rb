# app.rb
class Person
  attr_reader :name, :age

  def initialize(name, age)
    @name = name
    @age = age
  end
end

class Student < Person
  attr_reader :permissions

  def initialize(name, age, permissions = [])
    super(name, age)
    @permissions = permissions
  end
end

class Teacher < Student
  attr_reader :specialization

  def initialize(name, age, specialization)
    super(name, age)
    @specialization = specialization
  end
end

class Book
  attr_reader :title, :author

  def initialize(title, author)
    @title = title
    @author = author
  end
end

class App
  def initialize
    @people = []
    @books = []
  end

  def add_person(person)
    @people << person
  end

  def add_book(book)
    @books << book
  end

  def list_people
    @people
  end

  def list_books
    @books
  end
end

app = App.new
app.add_person(Person.new('Alice', 25))
app.add_person(Student.new('Bob', 30, 'Teacher'))
app.add_person(Teacher.new('Charlie', 35, 'Math'))

app.list_people.each do |person|
  puts "#{person.name} (#{person.age})"
end

app.list_books.each do |book|
  puts "#{book.title} by #{book.author}"
end