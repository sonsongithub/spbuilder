
require 'plist'
require 'cfpropertylist'

xml_path = "./sample/Answers/Contents/Manifest.plist"
hash = Plist::parse_xml(File.expand_path xml_path)
puts hash

hash = Hash.new
hash["Version"] = "1.0"
hash["Name"] = "hoge"
hash["Pages"] = []

plist = CFPropertyList::List.new
plist.value = CFPropertyList.guess(hash)
plist.save("./example.plist", CFPropertyList::List::FORMAT_XML)
