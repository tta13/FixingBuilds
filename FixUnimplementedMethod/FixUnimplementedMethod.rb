class FixUnimplementedMethod

  def initialize(projectName, projectPath, baseCommit, filePath, duplicatedMethod, className)
    @projectPath = projectPath
    @baseCommit = baseCommit
    @filePath = filePath
    @duplicatedMethod = duplicatedMethod
    @projectName = projectName
    @initialPath = ""
    @className = className
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
    #puts mergeFileContent

    startScope, endScope = getClassScope(mergeFileContent, @className)
    startLine = mergeFileContent[0..startScope].count("\n") + 1
    endLine = mergeFileContent[0..endScope].count("\n") + 1


    #puts startLine, endLine
    #puts "Erasing duplicated"
    #eraseDuplicated(tempFile, startLine, endLine)
    #deleteClone()
    #makeCommit()



  end

  def getClassScope(fileContent, className)
    # classDeclaration = fileContent.scan(/[public |private |protected |^.]*[a-z]*[ ]+class .*[ ]*{/m)
    classDeclaration = fileContent.scan(/class[ ]*ConstantValueInstantiator [\w\.\-\<\>\p\?\[\]\, \n]*{/)[0]

    # search the declaration line
    classIndex = fileContent.index(classDeclaration)

    # search the begin and the end of the class
    startScope = classIndex + classDeclaration.length

    # possibleScope = originalFile[startLine, 0]
    endScope = fileContent[startScope..-1].index("}") + startScope

    numberOfOpenScope = fileContent[startScope..endScope].count("{")
    numberOfCloseScope = fileContent[startScope..endScope].count("}")

    while  numberOfOpenScope >= numberOfCloseScope do
      endScope = fileContent[endScope+1..-1].index("}") + endScope + 1

      numberOfOpenScope = fileContent[startScope..endScope].count("{")
      numberOfCloseScope = fileContent[startScope..endScope].count("}")
    end

    return startScope, endScope
  end

  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, deletion " << @duplicatedMethod << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end

end