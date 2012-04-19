#!/usr/bin/env rp5 run

# This sketch is for my Senior Recital (April 21st, 2012).
# Audience members will enter their name at a prompt.
# Later in the show, this sketch will play and select one
# of the entered names. The spiraling letters will part
# and make room for other letters for form the name
# of who shall be up next for the highly coveted
# "audience participant" opportunity. :P

class PVector
  def self.from_polar(radius, angle)
    PVector.new(radius*Math.cos(angle), radius*Math.sin(angle))
  end
end

class Letter
  include Processing::Proxy

  attr_accessor :char, :position

  def x; @position.x end
  def y; @position.y end

  def initialize(char='A', x_or_vec = 0, y = 0)
    @char = char

    if x_or_vec.kind_of? PVector
      @position = x_or_vec
    elsif
      @position = PVector.new(x_or_vec, y)
    end

    @radius = sqrt(@position.x**2 + @position.y**2)
    @angle = atan2(@position.y, @position.x)
    @sin_offset = rand * TWO_PI
  end

  def update(deltaTime)
    radflux = @radius + sin(@angle + @sin_offset) * 100.0
    @angle = (@angle + deltaTime).divmod(TWO_PI)[1]
    @position.x = cos(@angle) * radflux
    @position.y = sin(@angle) * radflux
  end

  def draw
    text(@char, @position.x, @position.y)
  end
end


class AudienceParticipantSelector < Processing::App
  Alphabet = ('A'..'Z').to_a

  attr_accessor :trx, :try, :do_rotate
  attr_reader :letters

  def setup
    @do_rotate = true

    @letters = (0...1000).map do
      Letter.new(Alphabet[rand(26)], PVector.from_polar((rand(width*1.5)+200) / 2.0, rand * TWO_PI))
      # Letter.new(Alphabet[rand(26)], rand(width-50) - ((width-50) / 2.0), rand(width-50) - ((width-50) / 2.0))
    end

    @timer = 0
    @trx = width / 2.0
    @try = height / 2.0
  end
  
  def draw
    translate(trx, try)
    background(0)
    deltaTime = millis / 1000.0 - @timer
    @timer += deltaTime

    if @do_rotate
      @letters.each { |l| l.update(deltaTime) }
    else
      @letters.each { |l| l.update(0) }
    end

    @letters.each { |l| l.draw }
  end
end

AudienceParticipantSelector.new :title => "Name Selector", :width => 1024, :height => 768
