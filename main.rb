require_relative './GitProject.rb'
require_relative 'FixMissingVar/UnavailableSymbolExtractor.rb'
require_relative 'FixMissingVar/BCUnavailableSymbol.rb'
require_relative 'FixMissingVar/FixUnavailableSymbol.rb'
require_relative 'FixDuplicatedMethod/DuplicatedMethodExtractor.rb'
require_relative 'FixDuplicatedMethod/BCDuplicatedMethod'
require_relative 'FixDuplicatedMethod/FixDuplicatedMethod'
require_relative 'FixUnimplementedMethod/UnimplementedMethodExtractor'
require_relative 'FixUnimplementedMethod/BCUnimplementedMethod'
require_relative 'FixUnimplementedMethod/FixUnimplementedMethod'

if ARGV.length < 1
  puts "invalid args, valid args example: "
  puts "grumTreePath projectPath"
  puts "projectPath is an optional param"
  return
end

# testing = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
# "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
# "attributeCharacteristics")
# testing.fix("buildTree", "")

# testing = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
#   "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
#   "attributeCharacteristics", 151)
# content = File.read("/home/arthurpires/Documents/faculdade/TAES/fixPatternRequestUpdate/baseCommitClone/src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java")
# testing.getMethodName(content, 151)
# return

# Pre setup
login = "tta13"
password = "notmypassword"

gumTree = ARGV[0]

if ARGV.length > 1
  Dir.chdir(ARGV[1])
end
projectPath = Dir.getwd

repLog = `#{"git config --get remote.origin.url"}`
if repLog == ""
  puts "invalid repository"
  return
end

projectName = repLog.split("//")[1]
projectName = projectName.split("github.com/").last.gsub("\n","")
commitHash = `#{"git rev-parse --verify HEAD"}`
commitHash = commitHash.gsub("\n", "")

# Init  Analysis
gitProject = GitProject.new(projectName, projectPath, login, password)
conflictResult = gitProject.conflictScenario(commitHash)
gitProject.deleteProject()
print conflictResult
print"\n"

conflictParents = conflictResult[1]
travisLog = gitProject.getTravisLog(commitHash)


#testing build conflicts
puts "testing unavailable symbol"
unavailableSymbolExtractor = UnavailableSymbolExtractor.new()
unavailableResult = unavailableSymbolExtractor.extractionFilesInfo(travisLog)
if unavailableResult[0] == "unavailableSymbolVariable"
   conflictCauses = unavailableResult[1]
   ocurrences = unavailableResult[2]

   bcUnavailableSymbol = BCUnavailableSymbol.new(gumTree, projectName, projectPath, commitHash,
     conflictParents, conflictCauses)
   bcUnSymbolResult = bcUnavailableSymbol.getGumTreeAnalysis()

   if bcUnSymbolResult[0] != ""
     baseCommit = bcUnSymbolResult[1]
     cause = bcUnSymbolResult[0]
     className = conflictCauses[0][0]
     callClassName = conflictCauses[0][2]
     methodNameByTravis = conflictCauses[0][1]
     conflictFile = conflictCauses[0][3].tr(":","")
     fileToChange = conflictFile.gsub(/\/home\/travis\/build\/[a-z|A-Z|0-9]+\/[a-z|A-Z|0-9]+\//,"")
     conflictLine = Integer(conflictCauses[0][4].gsub("[","").gsub("]","").split(",")[0])
     newVariable = ""
      

     if className == callClassName
       puts "A build Conflict was detect, the conflict type is " + unavailableResult[0] + "."
       puts "Do you want fix it? Y or n"
       resp = STDIN.gets()
       # resp = "n"
        
       puts ">>>>>>>>>>>>>>>class"
       puts className
       puts ">>>>>>>>>>>>>>>method"
       puts methodNameByTravis
        
       if resp != "n" && resp != "N"
         fixer = FixUnavailableSymbol.new(projectName, projectPath, baseCommit, fileToChange, cause, newVariable, conflictLine, unavailableResult[0])
         fixer.fix(className)
       end
     end

      # TODO: get back deleted files
      # puts ">>>>>>>>>>>>>>>missing symbol"
      # puts cause
      # puts ">>>>>>>>>>>>>>>file "
      # puts conflictFile
      # puts ">>>>>>>>>>>>>>>fileToChange "
      # puts fileToChange
      # puts ">>>>>>>>>>>>>>>class"
      # puts className
      # puts ">>>>>>>>>>>>>>>method"
      # puts methodName
      # puts ">>>>>>>>>>>>>>>line"
      # puts conflictLine
      # puts ">>>>>>>>>>>>>>>base"
      # puts baseCommit
   end

elsif unavailableResult[0] == "unavailableSymbolMethod"
   puts "IM HERE"
   conflictCauses = unavailableResult[1]
   ocurrences = unavailableResult[2]
   puts "conflict causes : #{conflictCauses}"
   #return
   bcUnavailableSymbol = BCUnavailableSymbol.new(gumTree, projectName, projectPath, commitHash,
                                                 conflictParents, conflictCauses)
   bcUnSymbolResult = bcUnavailableSymbol.getGumTreeAnalysis()
   # valores para o cenario 2
   # bcUnSymbolResult = [["empty", "nil"], "139fe62d58e2946ab49eb4495e111d30036197a6\n"]
   # valores para o cenario 1
   #bcUnSymbolResult = [["builder", "builderWithHighestTrackableLatencyMillis"], "4cf58a80635f5799440da084adc5b41e2139b3ab\n"]
   puts "bcUnSymbolResult : #{bcUnSymbolResult}"

   if bcUnSymbolResult[0][1] != ""
     baseCommit = bcUnSymbolResult[1]
     cause = bcUnSymbolResult[0][1]
     newSymbol = bcUnSymbolResult[0][0]
     className = conflictCauses[0][0]
     conflictFileName = conflictCauses[0][2]
     methodNameByTravis = conflictCauses[0][1]
     conflictFile = conflictCauses[0][3].tr(":","")
     fileToChange = conflictFile.split(projectName)
     conflictLine = Integer(conflictCauses[0][4].gsub("[","").gsub("]","").split(",")[0])

     puts "Entrei"
     puts bcUnSymbolResult

     puts bcUnSymbolResult[0][1]
     puts methodNameByTravis

     if bcUnSymbolResult[0][1] == methodNameByTravis
       puts "A build Conflict was detect, the conflict n is " + unavailableResult[0] + "."
       puts "Do you want fix it? Y or n"
       resp = STDIN.gets()
       # resp = "n"

       puts ">>>>>>>>>>>>>>>class"
       puts className
       puts ">>>>>>>>>>>>>>>method"
       puts methodNameByTravis

       if resp != "n" && resp != "N"
         fixer = FixUnavailableSymbol.new(projectName, projectPath, baseCommit, fileToChange[1], cause, newSymbol, conflictLine, unavailableResult[0])
         puts conflictLine
         fixer.fix(className)
         puts "I did it"
       end
     end
   else
      puts "nao entrei"
   end
end

puts "testing unimplemented method"
unimplementedMethodExtractor = UnimplementedMethodExtractor.new()
unimplementedResult = unimplementedMethodExtractor.extractionFilesInfo(travisLog)
if unimplementedResult[0] == "unimplementedMethod" or unimplementedResult[0] == "unimplementedMethodSuperType"
  puts "Identifiquei"
  conflictCauses = unimplementedResult[1]
  ocurrences = unimplementedResult[2]
  puts "causes : #{conflictCauses}"
  puts "ocurrences : #{ocurrences}"
  puts "done"
  bcUnimplementedMethod = BCUnimplementedMethod.new(gumTree, projectName, projectPath, commitHash,
                                              conflictParents, conflictCauses)
  bcUnimplementedResult = bcUnimplementedMethod.getGumTreeAnalysis()
  #bcUnimplementedResult = [true, "bba652c16f45fdb83956f6093b88f0efb88df584\n"]
  puts "bcUnimplementedResult : #{bcUnimplementedResult}"
  if bcUnimplementedResult[0] == true
    #puts "its good"
    baseCommit = bcUnimplementedResult[1]
    conflictFile = conflictCauses[0][2]
    fileToChange = conflictFile.split(projectName)
    aux = conflictCauses[0][4].split(".")[0]
    aux1 = conflictFile.split(aux)
    conflictFile2 = conflictCauses[0][4].gsub(".", "/")
    fileToRead = aux1[0] + conflictFile2
    fileToRead = fileToRead.split(projectName)
    cause = conflictCauses[0][5]
    className = conflictCauses[0][1]
    puts fileToChange, baseCommit, cause
    puts "A build Conflict was detect, the conflict n is " + unimplementedResult[0] + "."
    puts "Do you want fix it? Y or n"
    resp = STDIN.gets()
    # resp = "n
    if resp != "n" && resp != "N"
      fixer = FixUnimplementedMethod.new(projectName, projectPath, baseCommit, fileToChange[1], fileToRead[1], cause, className)
      fixer.fix(className)
      puts "I did it"
    end
  end
end

puts "testing duplicated method"
duplicatedMethodExtractor = DuplicatedMethodExtractor.new()
duplicatedResult = duplicatedMethodExtractor.extractionFilesInfo(travisLog)
if duplicatedResult[0] == "statementDuplication"
  puts "entrei"
  conflictCauses = duplicatedResult[1]
  ocurrences = duplicatedResult[2]
  puts "causes : #{conflictCauses}"
  puts "ocurrences : #{ocurrences}"
  puts "done"
  bcDuplicatedMethod = BCDuplicatedMethod.new(gumTree, projectName, projectPath, commitHash,
                                              conflictParents, conflictCauses)
  bcDuplicatedResult = bcDuplicatedMethod.getGumTreeAnalysis()
  #bcDuplicatedResult = [true, "91d37f264a5bf65d7a1d1aec943ff470f9c2cad8\n"]
  puts "bcDuplicatedResult : #{bcDuplicatedResult}"
  if bcDuplicatedResult[0] == true
    puts "is true"
    baseCommit = bcDuplicatedResult[1]
    cause = conflictCauses[0][2]
    className = conflictCauses[0][0]
    conflictFile = conflictCauses[0][4].tr(":","")
    fileToChange = conflictFile.split(projectName)
    conflictLine = Integer(conflictCauses[0][5].gsub("[","").gsub("]","").split(",")[0])
    puts fileToChange, className, cause, baseCommit, conflictLine
    puts "A build Conflict was detect, the conflict n is " + duplicatedResult[0] + "."
    puts "Do you want fix it? Y or n"
    resp = STDIN.gets()
    # resp = "n"
    puts ">>>>>>>>>>>>>>>class"
    puts className
    puts ">>>>>>>>>>>>>>>method"
    puts methodNameByTravis

    if resp != "n" && resp != "N"
      fixer = FixDuplicatedMethod.new(projectName, projectPath, baseCommit, fileToChange[1], cause, conflictLine)
      puts conflictLine
      fixer.fix(className)
      puts "I did it"
    end
  end
end

puts "FINISHED!"