require "stringio"
require "test/unit"

require "gtp"

class MockPipe
  def self.popen(command, mode)
    new(command, mode)
  end
  
  def initialize(command, mode)
    @command       = command
    @mode          = mode
    @commands_sent = StringIO.new
    queue_responses("=1")
  end
  
  attr_reader :command, :mode
  
  def queue_responses(responses)
    @responses_receives = StringIO.new(responses)
  end
  
  def puts(*args)
    @commands_sent.puts(*args)
  end
  
  def method_missing(meth, *args, &blk)
    @responses_receives.send(meth, *args, &blk)
  end
end

class GTP
  IO = MockPipe
  def pipe
    @gnugo
  end
end

class TestGTP < Test::Unit::TestCase
  def teardown
    if @gtp
      @gtp.quit rescue nil
      @gtp = nil
    end
  end
  
  def test_gnugo_is_invoked_in_gtp_mode
    assert_match(/--mode gtp/, gtp.pipe.command)
  end
  
  def test_the_pipe_is_opened_in_read_and_write_mode
    assert_match(/\A[rwa]\+\z/, gtp.pipe.mode)
  end
  
  def test_quit_closes_the_io
    gtp.quit
    assert(gtp.pipe.closed?, "Did not close")
  end
  
  def test_can_pass_arguments_to_gnugo
    assert_match(/--boardsize 9/, gtp(boardsize: 9).pipe.command)
  end
  
  def test_quit_ends_the_session
    assert(gtp.quit, "Could not quit")
  end
  
  def test_can_retrieve_boardsize
    queue_responses "=1 19"
    assert_equal("19", gtp.query_boardsize)
  end
  
  def test_can_play_valid_move
    assert(gtp.play(:black, "E4"), "Could not play move")
  end
  
  def test_an_invalid_move_creates_an_error
    queue_responses "?1 invalid color or coordinate"
    assert(!gtp.play(:black, "Z4"), "Could play invalid move")
    assert_equal("invalid color or coordinate", gtp.error)
  end
  
  def test_genmove
    queue_responses "=1 D4"
    assert_match(/\A[A-HJ-T](1\d|[1-9])\z/, gtp.genmove(:black))
  end
  
  def test_showboard_tracks_board_state
    queue_responses "=1#{"x\n" * 21}\n=2#{"y\n" * 21}"
    board = gtp.showboard
    assert_operator(board.lines.to_a.size, :>=, 19)
    gtp.play(:black, "E4")
    assert_not_equal(board, gtp.showboard)
  end
  
  private
  
  def gtp(*args)
    @gtp ||= GTP.new(*args)
  end
  
  def queue_responses(*args)
    gtp.pipe.queue_responses(*args)
  end
end
