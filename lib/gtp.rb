class GTP
  def initialize(options = { })
    args   = options.map { |k, v| ["--#{k}", v] }.join(" ")
    @gnugo = IO.popen("gnugo --mode gtp #{args}".strip, "r+")
    @id    = 0
    @error = nil
  end
  
  attr_reader :error
  
  def success?
    @error.nil?
  end
  
  def quit
    send_command(:quit)
    @gnugo.close
    success?
  end
  
  def query_boardsize
    send_command(:query_boardsize)
  end
  
  def play(color, move)
    send_command(:play, color, move)
    success?
  end
  
  def genmove(color)
    send_command(:genmove, color)
  end
  
  def showboard
    send_command(:showboard)
  end
  
  private
  
  def send_command(command, *args)
    @gnugo.puts "#{@id += 1} #{command} #{args.join(' ')}".strip
    response = @gnugo.take_while { |line| line != "\n" }.join
    if response.sub!(/\A=#{@id}\s*/, "")
      @error = nil
    # James is evil, but regex are not!
    elsif response.sub!(/\A\?#{@id}\s*(\S.*\S)\s*/, "")
      @error = $1
    end
    response.sub(/\A(?:[ \t]*\n)+/, "").rstrip
  end
end