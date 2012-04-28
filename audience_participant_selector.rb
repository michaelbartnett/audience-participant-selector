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

  def polar_radius
    Math.sqrt(x**2 + y**2)
  end

  def polar_angle
    Math.atan2(y, x)
  end
end


class SketchEntity
  attr_accessor :current_behavior, :position

  def x; @position.x end
  def x=(value); @position.x = value end
  def y; @position.y end
  def y=(value); @position.y = value end

  def initialize(args)
    unless (@position = args[:position])
      @position = PVector.new(args[:x] || 0, args[:y] || 0)
    end
    @behavior_stack = []
    @current_behavior = args[:behavior]
    return if @current_behavior == nil
    @current_behavior.entity = self
    @behavior_stack.push(@current_behavior)
  end

  def push_behavior(behavior)
    return if !behavior
    @behavior_stack.push(behavior)
    @current_behavior = behavior
  end

  def pop_behavior
    old_behavior = @behavior_stack.pop
    @current_behavior = @behavior_stack.last
    old_behavior
  end

  def update(deltaTime)
    @current_behavior.update(deltaTime) if @current_behavior && @current_behavior.respond_to?(:update)
    _update if respond_to? :_update
  end

  def draw
    @current_behavior.predraw if @current_behavior && @current_behavior.respond_to?(:predraw)
    _draw if respond_to? :_draw
    @current_behavior.postdraw if @current_behavior && @current_behavior.respond_to?(:postdraw)
  end
end


class Behavior
  attr_reader :entity

  def initialize(entity = nil)
    self.entity = entity
  end

  def entity=(entity)
    @entity = entity
    on_entity_changed if respond_to? :on_entity_changed
  end
end


class SwirlBehavior < Behavior
  include Processing::Proxy

  attr_accessor :radius, :angle

  def update(deltaTime)
    return if entity == nil
    radflux = @radius + Math.sin(@angle + @sin_offset) * 100.0
    @angle = (@angle + deltaTime) % TWO_PI
    entity.x = cos(@angle) * radflux
    entity.y = sin(@angle) * radflux
  end

  def on_entity_changed
    @angle = @entity ? @entity.position.polar_angle : nil
    @sin_offset = @entity ? rand * TWO_PI : nil
    @radius = @entity ? @entity.position.polar_radius : nil
  end
end


class GTFOBehavior < Behavior
  include Processing::Proxy
  attr_accessor :new_position, :original_position
  attr_reader :state

  def state=(value)
    @state = value if value == :out || value == :in
    case @state
    when :in
      @target_position = @original_position
    when :out
      @target_position = @new_position
    end
  end

  def update(deltaTime)
    return if entity == nil || @progress >= 1.0
    @progress += deltaTime / 100.0
    entity.x = lerp(entity.x, @target_position.x, @progress)
    entity.y = lerp(entity.y, @target_position.y, @progress)
    puts "POPME is #{@popme}"
    entity.pop_behavior if @popme and @progress >= 1.0
  end

  def flip_state
    case self.state
    when :in then self.state = :out
    when :out then self.state = :in
    end
    @progress = 0.0
  end

  def return_and_pop
    puts "Getting ready to pop"
    state = :in
    @popme = true
  end

  def on_entity_changed
    @state = :out
    @popme = false
    @original_position = entity.position.get
    @new_position = PVector.from_polar(entity.position.polar_radius + width / 1.7, entity.position.polar_angle)
    @new_position.add(@original_position)
    @target_position = @new_position
    @progress = 0.0
  end
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
    @gtfo_gate = 0

    @letters = (0...1).map do
      letter = Letter.new Alphabet[rand(26)],
      {
        :position => PVector.from_polar((rand(width*0.7)+200) / 2.0, rand * TWO_PI),
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

  def keyPressed
    puts "KEYPRESS: #{key}"
    puts "len = #{key.length}"
    case key
    when ' '
      if @gtfo_gate == 0
        @letters.each do |l|
          l.push_behavior GTFOBehavior.new(l)
        end
        @gtfo_gate++
      else
        @letters.each do |l|
          l.current_behavior.flip_state
        end
      end
    when 'r'
      puts "DERP"
      @letters.each do |l|
        l.current_behavior.return_and_pop
      end
    end
  end

  def mouseClicked
    if !@gtfo_gate
      @gtfo_gate = true
    else

    end
  end
end

$myapp = AudienceParticipantSelector.new :title => "Audience Participant Selector", :width => 1024, :height => 768
