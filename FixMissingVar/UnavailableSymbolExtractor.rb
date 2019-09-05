class UnavailableSymbolExtractor

	def initialize()

	end

	def extractionFilesInfo(buildLog)
		stringNotFindType = "not find: type"
		stringNotMember = "is not a member of"
		stringErro = "ERROR"
		categoryMissingSymbol = ""

		filesInformation = []
		numberOcccurrences = buildLog.scan(/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,]* cannot find symbol[\n\r]+\[ERROR\]?[ \t\r\n\f]*symbol[ \t\r\n\f]*:[ \t\r\n\f]*method [a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*[\n\r]+\[ERROR\]?[ \t\r\n\f]*location[ \t\r\n\f]*:[ \t\r\n\f]*class[ \t\r\n\f]*[a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*[\n\r]?|\[#{stringErro}\][\s\S]*#{stringNotFindType}|\[#{stringErro}\][\s\S]*#{stringNotMember}|\[ERROR\]?[\s\S]*cannot find symbol/).size
		begin
			if (buildLog[/\[ERROR\]?[\s\S]*cannot find symbol/] || buildLog[/\[ERROR\] [a-zA-Z0-9\/\-\.\:\[\]\,]* cannot find symbol[\n\r]+\[ERROR\]?[ \t\r\n\f]*symbol[ \t\r\n\f]*:[ \t\r\n\f]*method [a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*[\n\r]+\[ERROR\]?[ \t\r\n\f]*location[ \t\r\n\f]*:[ \t\r\n\f]*class[ \t\r\n\f]*[a-zA-Z0-9\/\-\.\:\[\]\,\(\)]*[\n\r]?/] || buildLog[/\[javac\] [\/a-zA-Z\_\-\.\:0-9 ]* cannot find symbol/])
				if (buildLog[/error: package [a-zA-Z\.]* does not exist/])
					return getInfoSecondCase(buildLog, buildLog)
				elsif (buildLog[/error: cannot find symbol/])
					return getInfoThirdCase(buildLog)
				else
					return getInfoDefaultCase(buildLog)
				end
			else
				puts "dale cps"
				return categoryMissingSymbol, [], 0
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

	def getInfoThirdCase(buildLog)
		filesInformation = []
		classFiles = buildLog.to_enum(:scan, /\[ERROR\][a-zA-Z0-9\/\.\: \[\]\,\-]* error: cannot find symbol/).map { Regexp.last_match }
		count = 0
		while(count < classFiles.size)
			classFile = classFiles[count].to_s.split(".java")[0].to_s.split("\/").last
			positionInformation = classFiles[count].to_s.match(/\[[0-9,]+\]/)[0].gsub("[","").gsub("]","").split(",")
			filesInformation.push([classFile, positionInformation[0], positionInformation[1]])
			count += 1
		end
		if (filesInformation.size < 1)
			classFiles = buildLog.to_enum(:scan, /[a-zA-Z0-9\/\.\: \[\]\,\-]* error: cannot find symbol/).map { Regexp.last_match }
			count = 0
			while(count < classFiles.size)
				classFile = classFiles[count].to_s.split(".java")[0].to_s.split('\/').last
				filesInformation.push(classFile)
				count += 1
			end
		end
		return "unavailableSymbolFileSpecialCase", filesInformation, filesInformation.size
	end

	def getInfoSecondCase(buildLog)
		methodNames = buildLog.to_enum(:scan, /\[javac\] [\/a-zA-Z\_\-\.\:0-9]* cannot find symbol[\s\S]* \[javac\] (location:)+/).map { Regexp.last_match }
		categoryMissingSymbol = getTypeUnavailableSymbol(methodNames[0])
		filesInformation = []
		methodNames = buildLog.to_enum(:scan, /error: package [a-zA-Z\.]* does not exist/).map { Regexp.last_match }
		count = 0
		while (count < methodNames.size)
			packageName = methodNames[count].to_s.split("package ").last.to_s.gsub(" does not exist")
			count += 1
			filesInformation.push([packageName])
		end
		return categoryMissingSymbol, filesInformation, filesInformation.size
	end

	def getCallClassFiles(buildLog)
		if (buildLog.include?('Retrying, 3 of 3'))
			aux = buildLog[/BUILD FAILURE[\s\S]*/]
			return aux.to_s.to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,\_]* cannot find symbol/).map { Regexp.last_match }
		else
			return buildLog[/Compilation failure:[\s\S]*/].to_enum(:scan, /\[ERROR\]?[ \t\r\n\f]*[\/\-\.\:a-zA-Z\[\]0-9\,]* cannot find symbol/).map { Regexp.last_match }
		end
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

end

#log = "Retrying, 3 of 3  [INFO] BUILD FAILURE [INFO] ------------------------------------------------------------------------ [INFO] Total time: 7.958s [INFO] Finished at: Sat Feb 22 16:16:05 UTC 2014 [INFO] Final Memory: 20M/191M [INFO] ------------------------------------------------------------------------ [ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.0:compile (default-compile) on project okhttp-protocols: Compilation failure [ERROR] /home/travis/build/square/okhttp/okhttp-protocols/src/main/java/com/squareup/okhttp/internal/bytes/GzipSource.java:[93,29] cannot find symbol [ERROR] symbol:   variable deadline [ERROR] location: class com.squareup.okhttp.internal.bytes.GzipSource [ERROR] -> [Help 1] [ERROR]  [ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch. [ERROR] Re-run Maven using the -X switch to enable full debug logging. [ERROR] "
#unavailableSymbolExtractor = UnavailableSymbolExtractor.new()
#print unavailableSymbolExtractor.extractionFilesInfo(log)
# Retorno: ["unavailableSymbolVariable", [["GzipSource", "deadline", "GzipSource"]], 1]
# O primeiro elemento diz respeito ao tipo de simbolo indisponivel
# O segundo elemento as informaçoes associadas
# E o terceiro o numero de ocorrencias