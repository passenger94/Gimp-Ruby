

class Shoes::Spinner < Shoes::Widget
    attr_accessor :state, :value, :textval
    
    def initialize opts = {}
        @label = opts[:label] || "label"
        @value = opts[:default] || 1
        @range = opts[:range] || (0..100)
        @step = opts[:step] || 1
        @state = opts[:state] || nil
        @w = opts[:w] || (@label.length * 10) + 40
        self.width = @w
        
        flow do
            @title = para @label + " "
            @textval = edit_line( @value.to_s, :state => @state, :width => 50) do |el|
              @value = el.text.to_i
            end
            stack :width => 15 do
                @up = flow :margin => 1, :width => 15, :height => 14 do
                    border black
                    rotate 90
                    arrow 11,2,10, :center => true
                end
                @down = flow :margin => 1, :width => 15, :height => 14 do
                    border black
                    rotate 270
                    arrow 2,10,10, :center => true
                end
            end
        end
        
        @up.click {increment}
        @down.click {decrement}
    end
    
    def state=(st)
        @state = st
        @textval.state = st
        if @state == nil
            @up.click {increment}
            @down.click {decrement}
            @textval.text = @textval.text + "\n" # triggering change event on edit_line
        else
            [@up,@down].each {|e| e.click {}}
        end
    end
    
    def increment
        @textval.text = (@textval.text.to_i + @step).to_s if @range.include?(@textval.text.to_i+@step)
    end
    
    def decrement
        @textval.text = (@textval.text.to_i - @step).to_s if @range.include?(@textval.text.to_i-@step)
    end
    
    def value=(val)
        @value = val
        @textval.text = @value.to_s
    end
end


class Shoes::Slider < Shoes::Widget
    attr_accessor :state, :value, :label, :w
    
    def initialize opts = {}
        @label = opts[:label] || "label"
        @range = opts[:range] || (0..10)
        @w = opts[:w] || ((@label.length+3) * 5)
        @slidewidth = opts[:slidewidth] || 100
        @ratio = @slidewidth.to_f/(@range.end - @range.begin).abs
        #@ratio = 100.0/(@range.end - @range.begin).abs
        @offset = @range.begin.to_f
        @value = opts[:default] || 1
        if !@range.include?(@value)
            alert "default value : #{opts[:default]} is out of range : #{@range} !" +
                                "\nin #{self.inspect}\n\ndefaulting to minimum : #{@range.begin}"
            @value = @range.begin
        end
        @step = opts[:step] || 1
        @state = opts[:state] || nil
        @released = true
        self.style(:width => @w + @slidewidth + 73) #self.width = @w + @slidewidth + 73
        
        flow :margin => 0 do
            #border green
            flow :width => @w do
                #border blue
                title = inscription @label + " ", :margin => 1, :align => "right"
            end
            stack :width => @slidewidth+20 do
                #border yellow
                stroke black
                line 8, 12, @slidewidth+8, 12
                @arr = image :width => 15, :height => 14 do
                    stroke black
                    rotate 270
                    arrow 11,11,10, :center => true
                end
            end
            
            @el = edit_line @value, :state => @state, :margin => 0, :width => 50, :height => 20 do |edit|
                @valuechanged = false
                val = edit.text.sub(",",".").to_f
                if @range.include?(val)
                    @value = val
                    @valuechanged = true
                    @arr.displace(((@value - @offset)*@ratio).to_i, 0)
                else
                    warn "value : #{val} out of range : #{@range}"
                end
            end if @released == true
            
        end
        
        @arr.displace(((@value - @offset)*@ratio).to_i, 0)
        
        self.state= @state
    end
    
    def state=(st)
        @state = st
        @el.state = st
        if @state == nil
            @arr.click {|im| slide}
        else
            @arr.click {}
        end
    end
    
    def slide
        b, origin_left, t = self.app.mouse
        @released = false
        origin_pos = ((@value - @offset)*@ratio).to_i
        self.app.motion do |lf ,tp|
            pos = (origin_pos - (origin_left - lf))
            unless @released || pos < 0 || pos > @slidewidth
                self.value = ((pos.divmod(@step*@ratio))[0]*@step) + @offset
                @arr.displace(((@value - @offset)*@ratio).to_i, 0)
            end
        end
        self.app.release {|b,l,t| @released = true}
    end
    
    def value=(val)
        @value = val
        @el.text = @value
    end
    
=begin
    def valuechanged?
        @value = @value
        return @valuechanged
    end
=end

end


class Shoes::SliderCombo < Shoes::Widget
    attr_accessor :value1, :value2, :w, :linked
    
    def initialize opts = {}
        @w = opts[:w] || 50
        @slidewidth = opts[:slidewidth] || nil
        @step = opts[:step] || 1
        @value1 = @value2 = opts[:default] || 1
        @label1 = opts[:label1] || "label1"
        @label2 = opts[:label2] || "label2"
        @range1 = opts[:range1] || (0..10)
        @range2 = opts[:range2] || (0..10)
        @linked = opts[:linked].is_a?(FalseClass) ? false : true
        @state = @linked ? "disabled" : nil
        
        flow do
            #border black
            stack do
                @s1 = slider :label => @label1, :state => @state, :margin => 1, :w => @w,
                                            :range => @range1, :step => @step, :default => @value1, :slidewidth => @slidewidth
                @s2 = slider :label => @label2, :margin => 1, :w => @w, :range => @range2,
                                            :step => @step, :default => @value2, :slidewidth => @slidewidth
            end
            sw = self.width = @s1.style[:width] + 30
            @s2.move(0,34)
            @chain = image "chained.png"
            @chain.move(sw-25, 0)
        end
        
        @chain.click do |im|
            if im.path == "chained.png"
                im.path = "chained_un.png"
                @s1.state = nil
                anim(false)
            else
                im.path = "chained.png"
                @s1.state = "disabled"
                anim(true)
            end
        end
        
        self.linked= @linked
        
    end
    
    def linked=(st)
        @linked = st
        if @linked == true
            @chain.path = "chained.png"
            anim(true)
        else
            @chain.path = "chained_un.png"
            anim(false)
        end
    end
    
    def anim(chained)
        @t.stop and @t.remove if @t
        @t = animate(8) do
            if chained
                @value2 = @value1 = @s1.value = @s2.value
            else
                @value1 = @s1.value
                @value2 = @s2.value
            end
        end
    end
    
    def value1=(val)
        @value1 = val
        @s1.value = @value1
    end
    
    def value2=(val)
        @value2 = val
        @s2.value = @value2
    end
end


class Shoes::ColorChooser < Shoes::Widget
    attr_accessor :color, :label, :w
    attr_reader :gimpcolor
    
    def initialize opts = {}
        @color = opts[:color] || rgb(0, 255, 0)
        @gimpcolor = [@color.red, @color.green, @color.blue]
        @label = opts[:label] || "color ? : "
        @w = opts[:w] || (@label.length * 10)
        self.width = @w + 50
        
        flow do
            para @label
            @ie = flow :width => 50, :height => 25, :margin => [0,3,0,0] do
                backgrd
            end
        end
        @ie.click {choose}
    end
    
    def choose
        @color = ask_color("pick a color")
        @gimpcolor = [@color.red, @color.green, @color.blue]
        @ie.clear {backgrd}
    end
    
    def backgrd
        image :width => 50, :height => 25 do
            image :width => 50, :height => 25 do #highlight
                nostroke
                fill rgb(255,255,255,1.0)
                rect 2,2,47,21,3
                blur 2
            end
            stroke rgb(115,106,96) #outline
            fill rgb(115,106,96)
            rect 0,0,48,20,3
            
            stroke rgb(238,234,230) #background
            fill rgb(238,234,230)
            rect 1,1,46,18,2
            
            stroke rgb(127,127,127,0.3) #shadow
            nofill
            rect 1,1,47,19,3
            
            stroke @color
            fill @color
            rect 3,3,42,14,3
        end
    end
    
end

