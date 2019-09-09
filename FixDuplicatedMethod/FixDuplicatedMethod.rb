class FixDuplicatedMethod

  def initialize(projectName, projectPath, baseCommit, filePath, duplicatedMethod, line)
    @projectPath = projectPath
    @baseCommit = baseCommit
    @filePath = filePath
    @duplicatedMethod = duplicatedMethod
    @projectName = projectName
    @line = line
    @initialPath = ""
  end

  def deleteClone()
    Dir.chdir(@initialPath)
    %x(rm -rf baseCommitClone/)
  end

  def fix(className)

    # cloning baseCommit
    puts "fixing..."
    @initialPath = Dir.getwd
    %x(git clone https://github.com/#{@projectName} baseCommitClone)
    Dir.chdir("baseCommitClone/")
    %x(git checkout #{@baseCommit})

    # getting declaration
    #baseFileContent = File.read(Dir.getwd + "/" + @filePath)
    # getting merge file
    mergeFileContent = File.read(@projectPath + "/" + @filePath)

    Dir.chdir(@projectPath)
    tempFile = File.new('arquivo.txt', 'w')
    tempFile.write(mergeFileContent)
    tempFile.close()
    tempFileContent = File.read(@projectPath + "/arquivo.txt")
    puts tempFileContent

    startScope, endScope = getMethodScope(mergeFileContent, @duplicatedMethod)
    startLine = mergeFileContent[0..startScope].count("\n") + 1
    endLine = mergeFileContent[0..endScope].count("\n") + 1

    #puts startLine, endLine
    #puts "Erasing duplicated"
    eraseDuplicated(tempFile, startLine, endLine)
    deleteClone()
    FileUtils.rm %w( arquivo.txt )
    log = %x(mvn clean install)
    if(!log.to_s.match(/\[INFO\] BUILD FAILURE/))
      puts "Do you want to commit the automatica changes? Y or N"
      resp = STDIN.gets()
      if !resp.match(/(n|N)/)
        makeCommit()
      end
    else
      puts "Your project still has some compilation errors"
    end

  end


  def getMethodScope(fileContent, methodName)
    # search for method name
    # methodDeclaration = fileContent.scan(/[^return].* #{@missingVar}[;| ].*;*/)
    # methodDeclarations = fileContent.scan(/[private |public |protected ]*[\W|\w|\<|\>]*[ ]+#{methodName}[ ]*\([\w|\W|\<|\>|,| ]*\)[ ]*{/)
    methodDeclaration = fileContent.scan(/#{methodName}[\p{Space}]*\([\w|\p{Space}|,|\?|\<|\>|\[|\]]*\)[\p{Space}]*{/)[0]


    # search the declaration line
    methodIndex = fileContent.index(methodDeclaration)

    # search the begin and the end of the method
    startScope = methodIndex + methodDeclaration.length

    # possibleScope = originalFile[startLine, 0]
    endScope = fileContent[startScope..-1].index("}") + startScope

    numberOfOpenScope = fileContent[startScope..endScope].count("{")
    numberOfCloseScope = fileContent[startScope..endScope].count("}")

    while  numberOfOpenScope >= numberOfCloseScope do
      endScope = fileContent[endScope+1..-1].index("}") + endScope + 1

      numberOfOpenScope = fileContent[startScope..endScope].count("{")
      numberOfCloseScope = fileContent[startScope..endScope].count("}")
    end

    return methodIndex, endScope
  end

  def eraseDuplicated(tempFile, startScope, endScope)
    puts "erasing..."
    puts startScope, endScope
    Dir.chdir(@projectPath)
    originalFile = File.open(@projectPath + "/" + @filePath, "w+")
    lineCount = 0

    File.open(tempFile, 'r+').each do |line|
      lineCount = lineCount + 1
      if lineCount < startScope or lineCount > endScope
        originalFile.write(line)
      end
    end

    originalFile.close()
    puts "Result saved in #{@projectPath + "/" + @filePath}"
  end

  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, deletion " << @duplicatedMethod << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end

end