class DuplicatedMethodExtractor

  def initialize()

  end

  def extractionFilesInfo(buildLog)
    categoryMissingSymbol = ""

    filesInformation = []
    numberOcccurrences = buildLog.scan(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,]+ method [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\<\>]* is already defined in class [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\<\>]*[\n\r]?/).size
    begin
      if (buildLog[/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,]+ method [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\<\>]* is already defined in class [a-zA-Z0-9\/\-\.\:\[\]\,\(\)\<\>]*[\n\r]?/])
        return getInfoDefaultCase(buildLog)
      end
    rescue
      return categoryMissingSymbol, [], 0
    end
  end

  def getInfoDefaultCase(buildLog)
    classFiles = []
    methodNames = []
    callClassFiles = []
    if (buildLog[/\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+/])
      methodNames = buildLog.to_enum(:scan, /\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+ [a-zA-Z\. ]*/).map { Regexp.last_match }
      classFiles = buildLog.to_enum(:scan, /\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+ [a-zA-Z\. ]*/).map { Regexp.last_match }
      callClassFiles = buildLog.to_enum(:scan, /\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+ [a-zA-Z\. ]*/).map { Regexp.last_match }
    else
        methodNames = buildLog.to_enum(:scan, /\[ERROR\][ \t\r\n\f]*symbol[ \t\r\n\f]*:[ \t\r\n\f]*[method|class|variable|constructor|static]*[ \t\r\n\f]*[a-zA-Z0-9\(\)\.\/\,\_]*[ \t\r\n\f]*(\[INFO\] )?\[ERROR\][ \t\r\n\f]*(location)?/).map { Regexp.last_match }
      classFiles = buildLog.to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*(location)?[ \t\r\n\f]*:[ \t\r\n\f]*(@)?[class|interface|variable instance of type|variable request of type)?|package]+[ \t\r\n\f]*[a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*[\n\r]?/).map { Regexp.last_match }
      callClassFiles = getCallClassFiles(buildLog)
    end
    categoryMissingSymbol = getTypeUnavailableSymbol(methodNames[0])
    filesInformation = []
    count = 0
    while (count < classFiles.size)
      methodName = methodNames[count].to_s.match(/symbol[ \t\r\n\f]*:[ \t\r\n\f]*(method|variable|class|constructor|static)[ \t\r\n\f]*[a-zA-Z0-9\_]*/)[0].split(" ").last
      classFile = classFiles[count].to_s.match(/location[ \t\r\n\f]*:[ \t\r\n\f]*(@)?(variable (request|instance) of type|class|interface)?[ \t\r\n\f]*[a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*/)[0].split(".").last.gsub("\r", "").to_s
      callClassFile = ""
      fileName = ""
      line = ""

      if (buildLog[/\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+/])
        callClassFile = classFile
        fileName = classFile
      else
        error = callClassFiles[count].to_s
        line = error[error.rindex("[")..error.rindex("]")]
        fileName = error.match(/\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z0-9\,\_]*/)[0]
        callClassFile = fileName.split("/").last.gsub(".java:", "").gsub("\r", "").to_s
        fileName = fileName[fileName.index('/')..-1]
      end

      count += 1
      filesInformation.push([classFile, methodName, callClassFile, fileName, line])
    end
    return categoryMissingSymbol, filesInformation, filesInformation.size
  end

  def getTypeUnavailableSymbol(methodNames)
    if (methodNames.to_s.match(/symbol[ \t\r\n\f]*:[ \t\r\n\f]*(method|constructor)[ \t\r\n\f]*[a-zA-Z0-9\_]*/))
      return "unavailableSymbolMethod"
    elsif (methodNames.to_s.match(/symbol[ \t\r\n\f]*:[ \t\r\n\f]*(variable)[ \t\r\n\f]*[a-zA-Z0-9\_]*/))
      return "unavailableSymbolVariable"
    elsif (methodNames.to_s.match(/error: package/))
      return "unavailablePackage"
    else
      return "unavailableSymbolFile"
    end
  end

  def getCallClassFiles(buildLog)
  if (buildLog.include?('Retrying, 3 of 3'))
    aux = buildLog[/BUILD FAILURE[\s\S]*/]
    return aux.to_s.to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,\_]* unavailable symbol method/).map { Regexp.last_match }
  else
    return buildLog[/Compilation failure:[\s\S]*/].to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,]* unavailable symbol method/).map { Regexp.last_match }
  end
end

end

#log = "Retrying, 3 of 3  [INFO] BUILD FAILURE [INFO] ------------------------------------------------------------------------ [INFO] Total time: 7.958s [INFO] Finished at: Sat Feb 22 16:16:05 UTC 2014 [INFO] Final Memory: 20M/191M [INFO] ------------------------------------------------------------------------ [ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.0:compile (default-compile) on project okhttp-protocols: Compilation failure [ERROR] /home/travis/build/square/okhttp/okhttp-protocols/src/main/java/com/squareup/okhttp/internal/bytes/GzipSource.java:[93,29] cannot find symbol [ERROR] symbol:   variable deadline [ERROR] location: class com.squareup.okhttp.internal.bytes.GzipSource [ERROR] -> [Help 1] [ERROR]  [ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch. [ERROR] Re-run Maven using the -X switch to enable full debug logging. [ERROR] "
#unavailableSymbolExtractor = UnavailableSymbolExtractor.new()
#print unavailableSymbolExtractor.extractionFilesInfo(log)
# Retorno: ["unavailableSymbolVariable", [["GzipSource", "deadline", "GzipSource"]], 1]
# O primeiro elemento diz respeito ao tipo de simbolo indisponivel
# O segundo elemento as informaçoes associadas
# E o terceiro o numero de ocorrencias