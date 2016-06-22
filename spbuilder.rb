
require 'plist'
require 'cfpropertylist'

class Page
  attr_accessor :name, :chapterName, :bookName
  def initialize(name, chapterName, bookName)
    @bookName = bookName
    @chapterName = chapterName
    if File.readable?(manifestPath(name, chapterName, bookName))
      hash = Plist::parse_xml(File.expand_path manifestPath(name, chapterName, bookName))
      @name = hash["Name"]
      @version = hash["Version"]
      @liveViewMode = hash["LiveViewMode"]
      @liveViewEdgeToEdge = hash["LiveViewEdgeToEdge"]
    else
      @name = name
      @version = "1.0"
      @liveViewMode = "VisibleByDefault" # or HiddenByDefault
      @liveViewEdgeToEdge = true         # or false
    end
    createDirectories
    createSources
  end

  def createSources
    directory = "./#{@bookName}.playgroundbook/Contents/Chapters/#{@chapterName}.playgroundchapter/Pages/#{name}.playgroundpage/"
    fw = File::open(directory + "Contents.swift", "w")
    fw.write("// Contents.swift")
    fw.close
    fw = File::open(directory + "LiveView.swift", "w")
    fw.write("// Contents.swift")
    fw.close
  end

  def createDirectories
    begin
      Dir.mkdir("./#{@bookName}.playgroundbook/Contents/Chapters/#{@chapterName}.playgroundchapter/Pages/#{@name}.playgroundpage")
      Dir.mkdir("./#{@bookName}.playgroundbook/Contents/Chapters/#{@chapterName}.playgroundchapter/Pages/#{@name}.playgroundpage/Resources/")
      Dir.mkdir("./#{@bookName}.playgroundbook/Contents/Chapters/#{@chapterName}.playgroundchapter/Pages/#{@name}.playgroundpage/Sources/")
    rescue => e
      puts e
    else
    end
  end

  def manifestPath(name = @name, chapterName = @chapterName, bookName = @bookName)
    "./#{bookName}.playgroundbook/Contents/Chapters/#{chapterName}.playgroundchapter/Pages/#{name}.playgroundpage/Manifest.plist"
  end

  def data
    {
      :Name => @name,
      :Version => @version,
      :LiveViewMode => @liveViewMode,
      :LiveViewEdgeToEdge => @liveViewEdgeToEdge,
    }
  end

  def updatePlist
    plist.save(manifestPath, CFPropertyList::List::FORMAT_XML)
  end

  def plist
    cfplist = CFPropertyList::List.new
    p data
    cfplist.value = CFPropertyList.guess(data)
    return cfplist
  end
end

class Chapter
  attr_accessor :name, :bookName
  def initialize(name, bookName)
    if File.readable?(manifestPath(name, bookName))
      hash = Plist::parse_xml(File.expand_path manifestPath(name, bookName))
      @name = hash["Name"]
      @bookName = bookName
      @version = hash["Version"]
      @pages = hash["Pages"].map {|item| if item =~ /^(.+?)\.playgroundpage$/; Page.new($1, @name, @bookName); end }
    else
      @name = name
      @version = "1.0"
      @bookName = bookName
      @pages = []
    end
  end

  def page(pageName)
    return addPage(pageName)
  end

  def addPage(pageName)
    newPage = Page.new(pageName, @name, @bookName)
    @pages.push(newPage)
    newPage.updatePlist
    updatePlist
    return newPage
  end

  def manifestPath(name = @name, bookName = @bookName)
    "./#{bookName}.playgroundbook/Contents/Chapters/#{name}.playgroundchapter/Manifest.plist"
  end

  def updatePlist
    plist.save(manifestPath, CFPropertyList::List::FORMAT_XML)
  end

  def data
    {
      :Name => @name,
      :Version => @version,
      :Pages => @pages.map {|item| item.name + ".playgroundpage"}
    }
  end

  def plist
    cfplist = CFPropertyList::List.new
    cfplist.value = CFPropertyList.guess(data)
    return cfplist
  end
end

class Book
  attr_accessor :name

  def initialize(name)
    if File.readable?(manifestPath(name))
      hash = Plist::parse_xml(File.expand_path manifestPath(name))
      @name = hash["Name"]
      @version = hash["Version"]
      @contentIdentifier = hash["ContentIdentifier"]
      @contentVersion = hash["ContentVersion"]
      # @imageReference = hash["ImageReference"]
      @deploymentTarget = hash["DeploymentTarget"]
      @chapters = hash["Chapters"].map {|item| if item =~ /^(.+?)\.playgroundchapter$/; Chapter.new($1, @name); end }
    else
      @name = name
      @version = "1.0"
      @contentIdentifier = "com.sonson.template." + name
      @contentVersion = "1"
      # @imageReference = name + ".png"
      @deploymentTarget = "ios10.0"
      @chapters = []
    end
  end

  def chapter(chapterName)
    @chapters.each{|item|
      return item if item.name == chapterName
    }
    return addChapter(chapterName)
  end

  def manifestPath(name = @name)
    "./#{name}.playgroundbook/Contents/Manifest.plist"
  end

  def addChapter(chapterName)
    newChapter = Chapter.new(chapterName, @name)
    @chapters.push(newChapter)
    begin
      Dir.mkdir("./#{@name}.playgroundbook/Contents/Chapters/#{chapterName}.playgroundchapter")
      Dir.mkdir("./#{@name}.playgroundbook/Contents/Chapters/#{chapterName}.playgroundchapter/Pages")
    rescue => e
      puts e
    else
    end
    newChapter.updatePlist
    updatePlist
    return newChapter
  end

  def updatePlist
    plist.save(manifestPath, CFPropertyList::List::FORMAT_XML)
  end

  def data
    {
      :Name => @name,
      :Version => @version,
      :ContentIdentifier => @contentIdentifier,
      :ContentVersion => @contentVersion,
      # :ImageReference => @imageReference,
      :DeploymentTarget => @deploymentTarget,
      :Chapters => @chapters.map {|item| item.name + ".playgroundchapter"}
    }
  end

  def plist
    cfplist = CFPropertyList::List.new
    cfplist.value = CFPropertyList.guess(data)
    return cfplist
  end

  def build
    begin
      Dir.mkdir(@name + ".playgroundbook")
      Dir.mkdir("./#{@name}.playgroundbook/Contents/")
      Dir.mkdir("./#{@name}.playgroundbook/Contents/Chapters")
      Dir.mkdir("./#{@name}.playgroundbook/Contents/Resources")
      plist.save(manifestPath, CFPropertyList::List::FORMAT_XML)
    rescue => e
      puts e
    else
    end
  end
end

def main
  command = ARGV[0]
  case command
  when "build"
    booktitle = ARGV[1]
    book = Book.new(booktitle)
    book.build
  when "chapter"
    booktitle = ARGV[1]
    chapterName = ARGV[2]
    book = Book.new(booktitle)
    chapter = book.chapter(chapterName)
  when "page"
    booktitle = ARGV[1]
    chapterName = ARGV[2]
    pageName = ARGV[3]
    book = Book.new(booktitle)
    chapter = book.chapter(chapterName)
    page = chapter.page(pageName)
  else
  end
end

main
