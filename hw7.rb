# University of Washington, Programming Languages, Homework 7, hw7.rb 
# (See also ML code)

# a little language for 2D geometry objects

# each subclass of GeometryExpression, including subclasses of GeometryValue,
#  needs to respond to messages preprocess_prog and eval_prog
#
# each subclass of GeometryValue additionally needs:
#   * shift
#   * intersect, which uses the double-dispatch pattern
#   * intersectPoint, intersectLine, and intersectVerticalLine for 
#       for being called by intersect of appropriate clases and doing
#       the correct intersection calculuation
#   * (We would need intersectNoPoints and intersectLineSegment, but these
#      are provided by GeometryValue and should not be overridden.)
#   *  intersectWithSegmentAsLineResult, which is used by 
#      intersectLineSegment as described in the assignment
#
# you can define other helper methods, but will not find much need to

# Note: geometry objects should be immutable: assign to fields only during
#       object construction

# Note: For eval_prog, represent environments as arrays of 2-element arrays
# as described in the assignment

class GeometryExpression  
  # do *not* change this class definition
  Epsilon = 0.00001
end

class GeometryValue 
  # do *not* change methods in this class definition
  # you can add methods if you wish

  private
  # some helper methods that may be generally useful
  def real_close(r1,r2) 
      (r1 - r2).abs < GeometryExpression::Epsilon
  end
  def real_close_point(x1,y1,x2,y2) 
      real_close(x1,x2) && real_close(y1,y2)
  end
  # two_points_to_line could return a Line or a VerticalLine
  def two_points_to_line(x1,y1,x2,y2) 
      if real_close(x1,x2)
        VerticalLine.new x1
      else
        m = (y2 - y1).to_f / (x2 - x1)
        b = y1 - m * x1
        Line.new(m,b)
      end
  end
  public
  # we put this in this class so all subclasses can inherit it:
  # the intersection of self with a NoPoints is a NoPoints object
  def intersectNoPoints np
    np # could also have NoPoints.new here instead
  end
  # it would have been better to simply use .class for @dispatch in GeometryValue 
  # but I had to avoid reflection for this assignment
  def intersect other
    eval("other.intersect#{@dispatch} self")  
  end
  def intersectPoint other
    eval("other.intersect#{@dispatch} self")
  end
  def intersectLine other
    eval("other.intersect#{@dispatch} self")
  end
  def intersectVerticalLine other
    eval("other.intersect#{@dispatch} self")
  end
  def intersectWithSegmentAsLineResult seg
    seg
  end  
  def preprocess_prog
    self
  end
  def eval_prog env 
    self
  end

  # we put this in this class so all subclasses can inhert it:
  # the intersection of self with a LineSegment is computed by
  # first intersecting with the line containing the segment which either returns a Line, a Point, or NoPoints
  # and then calling the result's intersectWithSegmentAsLineResult with the segment.
  def intersectLineSegment seg
    line_result = intersect(two_points_to_line(seg.x1,seg.y1,seg.x2,seg.y2))
    line_result.intersectWithSegmentAsLineResult seg
  end
  def inBetween(v,end1,end2)  # helper; checks if point v exists inside line segment.
    epsilon = GeometryExpression::Epsilon
    (end1 - epsilon <= v and v <= end2 + epsilon) or
    (end2 - epsilon <= v and v <= end1 + epsilon) 
  end
end

class NoPoints < GeometryValue
  # do *not* change this class definition: everything is done for you
  # (although this is the easiest class, it shows what methods every subclass
  # of geometry values needs)
  def initialize
    @dispatch = NoPoints    # it would have been better to simply use .class in GeometryValue but I had to avoid reflection for this assignment
  end
  # Note: no initialize method only because there is nothing it needs to do
  def shift(dx,dy)
    self # shifting no-points is no-points
  end
  # if self is the intersection of (1) some shape s and (2) 
  # the line containing seg, then we return the intersection of the 
  # shape s and the seg.  seg is an instance of LineSegment
  def intersectWithSegmentAsLineResult seg
    self
  end
end


class Point < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods

  # Note: You may want a private helper method like the local
  # helper function inbetween in the ML code
  attr_reader :x, :y
  def initialize(x,y)
    @x = x
    @y = y
    @dispatch = Point
  end
  def shift(dx,dy)
    Point.new(@x+dx, @y+dy)
  end
  def intersectPoint other
    if real_close_point(@x,@y,other.x,other.y)
      self
    else
      NoPoints.new
    end
  end
  def intersectLine other
    if real_close(@y, other.m * @x + other.b)
      self
    else
      NoPoints.new
    end
  end
  def intersectWithSegmentAsLineResult seg
    if inBetween(@x,seg.x1,seg.x2) and inBetween(@y,seg.y1,seg.y2)
      self
    else
      NoPoints.new
    end
  end  
  def intersectVerticalLine other
    if real_close(@x,other.x)
      self
    else 
      NoPoints.new
    end
  end
end

class Line < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :m, :b 
  def initialize(m,b)
    @m = m
    @b = b
    @dispatch = Line
  end
  def shift(dx,dy)
    Line.new(@m, @b + dy - (@m * dx))
  end
  def intersectLine other
    if real_close(@m,other.m)
      if real_close(@b,other.b)
        self
      else
        NoPoints.new
      end  
    else
      x = (other.b - @b)/(@m - other.m)
      Point.new(x, @m * x + @b)
    end
  end
  def intersectVerticalLine other
    Point.new(other.x,@m * other.x + @b)
  end
end

class VerticalLine < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :x
  def initialize x
    @x = x
    @dispatch = VerticalLine
  end
  def shift(dx,dy)
    VerticalLine.new(@x+dx)
  end
  def intersectVerticalLine other
    if real_close(@x, other.x)
      self
    else
      NoPoints.new
    end
  end
end

class LineSegment < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: This is the most difficult class.  In the sample solution,
  #  preprocess_prog is about 15 lines long and 
  # intersectWithSegmentAsLineResult is about 40 lines long
  attr_reader :x1, :y1, :x2, :y2
  def initialize (x1,y1,x2,y2)
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
    @dispatch = LineSegment
  end
  private
  def comp(v1,v2,if_true) # helper function for preprocess_prog
    v1 < v2 ? if_true : LineSegment.new(@x2,@y2,@x1,@y1)
  end
  public
  def preprocess_prog
    close_x = real_close(@x1,@x2) 
    close_y = real_close(@y1,@y2)
    case [close_x, close_y]
      when [true, true] then Point.new(@x1,@y1)
      when [true, false] then comp(@y1,@y2,self)
      when [false,false] then comp(@x1,@x2,comp(@y1,@y2,self))
      when [false,true] then comp(@x1,@x2,comp(@y1,@y2,self))
    end
  end
  def shift(dx,dy)
    LineSegment.new(@x1+dx, @y1+dy, @x2+dx, @y2+dy)
  end
  def intersectWithSegmentAsLineResult seg
    if real_close(@x1,@x2)
      tseg1,tseg2 = @y1 < seg.y1 ? [self,seg] : [seg,self]
      case
        when real_close(tseg1.y2, tseg2.y1) then Point.new(tseg1.x2,tseg1.y2)
        when tseg1.y2 < tseg2.y1 then NoPoints.new
        when tseg1.y2 > tseg2.y2 then LineSegment.new(tseg2.x1,tseg2.y1,tseg2.x2,tseg2.y2)
        else LineSegment.new(tseg2.x1,tseg2.y1,tseg1.x2,tseg1.y2)
      end
    else 
      tseg1,tseg2 = @x1 < seg.x1 ? [self,seg] : [seg,self]
      case 
        when real_close(tseg1.x2,tseg2.x1) then Point.new(tseg1.x2,tseg1.y2)
        when tseg1.x2 < tseg2.x1 then NoPoints.new
        when tseg1.x2 > tseg2.x2 then LineSegment.new(tseg2.x1,tseg2.y1,tseg2.x2,tseg2.y2)
        else LineSegment.new(tseg2.x1,tseg2.y1,tseg1.x2,tseg1.y2)
      end
    end 
  end  
end

# Note: there is no need for getter methods for the non-value classes

class Intersect < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(e1,e2)
    @e1 = e1
    @e2 = e2
  end
  def preprocess_prog
    Intersect.new(@e1.preprocess_prog, @e2.preprocess_prog)
  end
  def eval_prog env
    (@e1.eval_prog env).intersect @e2.eval_prog(env)
  end
end

class Let < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: Look at Var to guide how you implement Let
  def initialize(s,e1,e2)
    @s = s
    @e1 = e1
    @e2 = e2
  end
  def preprocess_prog
    Let.new(@s, @e1.preprocess_prog, @e2.preprocess_prog)
  end
  def eval_prog env
    @e2.eval_prog([[@s, @e1.eval_prog(env)]] + env)
  end
end

class Var < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize s
    @s = s
  end
  def eval_prog env # remember: do not change this method
    pr = env.assoc @s
    raise "undefined variable" if pr.nil?
    pr[1]
  end
  def preprocess_prog
    self
  end
end

class Shift < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(dx,dy,e)
    @dx = dx
    @dy = dy
    @e = e
  end
  def preprocess_prog
    Shift.new(@dx,@dy,@e.preprocess_prog)
  end
  def eval_prog env
    (@e.eval_prog env).shift(@dx,@dy)
  end
end
