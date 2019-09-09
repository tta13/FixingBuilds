class FixUnimplementedMethod

  def initialize(projectName, projectPath, baseCommit, filePath, fileToRead, unimplementedMethod, className)
    @projectPath = projectPath
    @baseCommit = baseCommit
    @filePath = filePath
    @fileToRead = fileToRead
    @unimplementedMethod = unimplementedMethod
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
    readFileContent = File.read(@projectPath + @fileToRead + ".java")
    methodDeclaration = readFileContent.scan(/[\w]* #{@unimplementedMethod}\(/)[0]
    type = methodDeclaration.split(" ")[0]

    startScope, endScope = getClassScope(mergeFileContent, @className)
    startLine = mergeFileContent[0..startScope].count("\n") + 1
    endLine = mergeFileContent[0..endScope].count("\n") + 1

    case type
    when "String"
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          return \"\";
      }
"
    when "Array"
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          [];
      }
"
    when "boolean"
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          return false;
      }
"
    when "char"
      declaration = "     @Override
      public Class<?> #{@unimplementedMethod}() {
          return '';
      }
"
    when "double"
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          return 0.0;
      }
"
    when "float"
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          return 0.0;
      }
"
    else
      declaration = "      @Override
      public Class<?> #{@unimplementedMethod}() {
          return 0;
      }
"
    end

    puts declaration

    Dir.chdir(@projectPath)
    tempFile = File.new('arquivo.txt', 'w')
    tempFile.write(mergeFileContent)
    tempFile.close()
    tempFileContent = File.read(@projectPath + "/arquivo.txt")
    puts tempFileContent


    setDeclaration(tempFile, declaration, endLine - 1)
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

  def getClassScope(fileContent, className)
    # classDeclaration = fileContent.scan(/[public |private |protected |^.]*[a-z]*[ ]+class .*[ ]*{/m)
    classDeclaration = fileContent.scan(/class[ ]*#{className} [\w\.\-\<\>\?\[\]\, \n]*{/)[0]

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

  def setDeclaration(tempFile, declaration, lineToInsert)
    puts "declaring..."
    puts lineToInsert
    Dir.chdir(@projectPath)

    originalFile = File.open(@projectPath + "/" + @filePath, "w+")
    lineCount = 0

    File.open(tempFile, 'r+').each do |line|
      lineCount = lineCount + 1
      originalFile.write(line)

      if lineCount == lineToInsert
        originalFile.write(declaration)
      end
    end

    originalFile.close()
    #tempFile.close()

    puts "Result saved in #{@projectPath + "/" + @filePath}"
  end

  def makeCommit()
    Dir.chdir(@projectPath)
    commitMesssage = "Build Conflict resolved automatic, insertion " << @unimplementedMethod << " declaration in " << @filePath
    %x(git add -u)
    %x(git commit -m "#{commitMesssage}")
  end

end