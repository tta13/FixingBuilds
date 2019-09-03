require_relative './GitProject.rb'
require_relative 'FixMissingVar/UnavailableSymbolExtractor.rb'
require_relative 'FixMissingVar/BCUnavailableSymbol.rb'
require_relative 'FixMissingVar/FixUnavailableSymbol.rb'
require_relative 'FixDuplicatedMethod/DuplicatedMethodExtractor.rb'
require_relative 'FixDuplicatedMethod/BCDuplicatedMethod'
require_relative 'FixDuplicatedMethod/FixDuplicatedMethod'

if ARGV.length < 1
  puts "invalid args, valid args example: "
  puts "grumTreePath projectPath"
  puts "projectPath is an optional param"
  return
end

# test = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
# "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
# "attributeCharacteristics")
# test.fix("buildTree", "")

# test = FixUnavailableSymbol.new("sanity/quickml", "/home/arthurpires/Documents/faculdade/TAES/quickml",
#   "d1b6903a40c8cd359bcd02fc34b837f41f48f1e9", "src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java",
#   "attributeCharacteristics", 151)
# content = File.read("/home/arthurpires/Documents/faculdade/TAES/fixPatternRequestUpdate/baseCommitClone/src/main/java/quickdt/predictiveModels/decisionTree/TreeBuilder.java")
# test.getMethodName(content, 151)
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

if conflictResult[0]
  conflictParents = conflictResult[1]
  travisLog = gitProject.getTravisLog(commitHash)

  unavailableSymbolExtractor = UnavailableSymbolExtractor.new()
  unavailableResult = unavailableSymbolExtractor.extractionFilesInfo(travisLog)
  puts unavailableResult[2]
  puts unavailableResult[1]
  puts unavailableResult[0]

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
          fixer = FixUnavailableSymbol.new(projectName, projectPath, baseCommit, fileToChange, cause, conflictLine, unavailableResult[0])
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

    #bcUnavailableSymbol = BCUnavailableSymbol.new(gumTree, projectName, projectPath, commitHash,
    #                                              conflictParents, conflictCauses)
    #bcUnSymbolResult = bcUnavailableSymbol.getGumTreeAnalysis()
    bcUnSymbolResult = [["empty", "nil"], "139fe62d58e2946ab49eb4495e111d30036197a6\n"]
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

else
  puts "test duplicated method"
  conflictParents = conflictResult[1]
  travisLog = gitProject.getTravisLog(commitHash)
  duplicatedMethodExtractor = DuplicatedMethodExtractor.new()
  duplicatedResult = duplicatedMethodExtractor.extractionFilesInfo(travisLog)
  puts duplicatedResult
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
      cause = conflictCauses[0][3]
      className = conflictCauses[0][1]
      conflictFile = conflictCauses[0][5].tr(":","")
      fileToChange = conflictFile.split(projectName)
      conflictLine = Integer(conflictCauses[0][6].gsub("[","").gsub("]","").split(",")[0])
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
end

puts "FINISHED!"
