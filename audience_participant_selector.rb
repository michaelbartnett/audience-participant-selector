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

class SwirlBehavior
  include Processing::Proxy

  attr_accessor :radius, :angle
  attr_reader :entity

  def entity=(entity)
    @entity = entity
    @angle = @entity ? atan2(@entity.y, @entity.x) : nil
    @sin_offset = @entity ? rand * TWO_PI : nil
    @radius = @entity ? sqrt(@entity.x**2 + @entity.y**2) : nil
  end

  def initialize(entity = nil)
    @entity = entity
    unless @entity == nil
      @angle = atan2(@entity.y, @entity.x)
      @sin_offset = rand * TWO_PI
      @radius = sqrt(@position.x**2 + @position.y**2)
    end
  end

  def update(deltaTime)    
    radflux = @radius + Math.sin(@angle + @sin_offset) * 100.0
    @angle = (@angle + deltaTime) % TWO_PI
    entity.x = cos(@angle) * radflux
    entity.y = sin(@angle) * radflux
  end

  def draw
    puts 'Behavior draw occurring'
  end
end

class SketchEntity
  attr_accessor :behavior
  attr_reader :position

  def x; @position.x end
  def x=(value); @position.x = value end
  def y; @position.y end
  def y=(value); @position.y = value end

  def initialize(args)
    unless (@position = args[:position])
      @position = PVector.new(args[:x] || 0, args[:y] || 0)
    end
    @behavior = args[:behavior]
    @behavior.entity = self unless @behavior == nil
  end

  def update(deltaTime)
    @behavior.update(deltaTime) if @behavior.respond_to?(:update)
    _update
  end

  def draw
    @behavior.draw if @behavior.respond_to? :draw
    _draw
  end

  private

  def _update
  end

  def _draw; end
end


class Letter < SketchEntity
  include Processing::Proxy

  def initialize(char='A', entity_args = { })
    if entity_args.kind_of? PVector
      super({ :position => entity_args })
    else
      super(entity_args)
    end

    @char = char
  end

  def _draw
    text(@char, x, y)
  end
end


class AudienceParticipantSelector < Processing::App
  load_libraries :opengl

  Alphabet = ('A'..'Z').to_a

  attr_accessor :trx, :try, :do_rotate
  attr_reader :letters

  def setup
    size width, height, OPENGL
    @do_rotate = true

    @letters = (0...800).map do
      letter = Letter.new Alphabet[rand(26)], 
      {
        :position => PVector.from_polar((rand(width*1.5)+200) / 2.0, rand * TWO_PI),
        :behavior => SwirlBehavior.new
      }
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
    @letters.each { |l| l.update(deltaTime) }
    @letters.each { |l| l.draw }
  end
end

AudienceParticipantSelector.new :title => "Audience Participant Selector", :width => 1024, :height => 768
