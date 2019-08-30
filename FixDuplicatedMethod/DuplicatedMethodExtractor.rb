class DuplicatedMethodExtractor

  def initialize()

  end

  def extractionFilesInfo(buildLog)
    #buildLog = build.match(/[\s\S]* BUILD FAILURE/)
    filesInformation = []
    numberOccurrences = buildLog.scan(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\s\<\>]* is already defined in [a-zA-Z0-9\/\-\.\:\[\]\,\_]* [a-zA-Z0-9]*/).size
    callClassFiles = getCallClassFiles(buildLog)
    begin
      information = buildLog.to_enum(:scan, /\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\s\<\>]* is already defined in [a-zA-Z0-9\/\-\.\:\[\]\,\_]* [a-zA-Z0-9]*/).map { Regexp.last_match }
      count = 0
      while(count < information.size)
        classFile = information[count].to_s.match(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,\s\<\>]*.java:/)[0].split("/").last.gsub('.java:','')
        variableName = ""
        if (information[count].to_s.match(/variable/) and information[count].to_s.match(/defined in method/))
          variableName = information[count].to_s.match(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\,]*\]\s[a-zA-Z0-9\/\-\_]* [a-zA-Z0-9]*/)[0].split(" ").last
        else
          variableName = "method"
        end
        error = callClassFiles[count].to_s
        line = error[error.rindex("[")..error.rindex("]")]
        fileName = error.match(/\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z0-9\,\_]*/)[0]
        puts "first", fileName
        callClassFile = fileName.split("/").last.gsub(".java:", "").gsub("\r", "").to_s
        fileName = fileName[fileName.index('/')..-1]
        methodName = information[count].to_s.match(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\,\]\s\_]*/)[0].split(" ").last
        count += 1
        puts error, line, fileName, callClassFile, methodName
        if (!methodName.include? ".")
          puts "im in bro"
          filesInformation.push(["statementDuplication", classFile, variableName, methodName,  callClassFile, fileName, line])
        end
      end
      puts "infos"
      puts filesInformation
      return "statementDuplication", filesInformation, information.size
    rescue
      return "statementDuplication", filesInformation, information.size
    end
  end

  def getCallClassFiles(buildLog)
    if (buildLog.include?('Retrying, 3 of 3'))
      aux = buildLog[/BUILD FAILURE[\s\S]*/]
      return aux.to_s.to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,\_]* method/).map { Regexp.last_match }
    else
      return buildLog[/Compilation failure:[\s\S]*/].to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,]* method/).map { Regexp.last_match }
    end
  end

end