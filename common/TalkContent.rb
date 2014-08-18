class TalkContent
  def initialize
    @content = []
    @jsonContent = []
    file = File.new('./common/talk.txt','r') 
    while line=file.gets  
        #puts line
        @content << line.chomp
        
        tmp = {'attached[]'=>'{}','body'=>  line.chomp  }
        @jsonContent << tmp
    end 
    @size = @content.size
    file.close
  end
  
  def getJsonContent index
    @jsonContent[index]
  end
  def getContent index
    @content[index]
  end
  
  def size
    @size
  end
  
end
