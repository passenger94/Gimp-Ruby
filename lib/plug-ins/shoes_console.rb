
class CustomButton < Shoes::Widget
    attr_accessor :block
    
    def initialize(label, options={}, &block)
        w_width = options[:w_width] ||= 115
        w_height = options[:w_height] ||= 25
        marg_b = options[:marg_b] ||= 30
        
        # bug in margins ! workaround : margin_bottom: marg_b and height: marg_b+25
        # if desired height is 25 (background height set to 25 accordingly)
        style(height: marg_b+w_height, margin_bottom: marg_b,
              width: w_width, margin_left: 15, margin_right: 15, margin_top: 0)
        
        back, fore = rgb(240,245,240), darkslategray
        back, fore = fore, back if options[:swap_colors]
        
        background back, curve: 5, height: w_height
        lbl = para label, stroke: fore, margin: [15,3,0,0], size: 12
        bkg = background yellow, curve: 5, hidden: true, height: w_height
        
        @block = block
        click {
            bkg.show
            Thread.new {sleep 0.05; bkg.hide}
            @block.call
        }
        
        hover { lbl.style(stroke: black) }
        leave { lbl.style(stroke: fore) }
    end
    
#   dbb = Shoes.APPS[1]; d = dbb.instance_variable_get :@display; f = d.contents[0]; f.contents;cb = f.contents[1]
end


Shoes.app title: "Shoes Irb <-> Gimp console", width:800, height: 600 do
    BUFFERSIZE = 1024
    #RE_IRBRETURN = /=>\s*\["?(.+)\]/ # with terminal
    RE_IRBRETURN = /\["?(.+)\]/       # without terminal
    RE_IRBRETURN_INFO = /(.+)", (\d), (\d+), (\d+)/
    @background_task = false
    @history, @pointer = [], 0
    
    keypress do |k|
        case k
        when :up
            @entry.text = @history[@pointer]
            @entry.to_end
            @pointer -= 1 unless @pointer == 0
        when :down
            @pointer += 1 unless @pointer == @history.size-1
            @entry.text = @history[@pointer]
            @entry.to_end
        else
            
        end
    end
    
    
    background darkslategray
    
    flow width: 1.0 do
        stack width: 115, attach: Shoes::Window do
            @side = inscription "", stroke: silver
            
            custom_button("Refresh", marg_b: 60) do
                mute_get { puts 'instance_variables.each {|iv|' +
                        'instance_variable_set(iv, nil) if iv.match(/layer\d+/) }' }
                @preamble.text = mute_get { puts "load 'imageDrawable4console.rb'" }
            end
            
            custom_button("Browse") { launch_db_browser }
            
            custom_button("Clear") { @console.text = "" }
            
            custom_button("Save", marg_b: 80) do 
                file = ask_save_file
                open(file, "w+") { |io| io << @console.text } if file
            end
            
            custom_button("Close") do
                puts "exit"; STDOUT.flush  # irb
                
                exit
            end
        end    
        
        @term = stack width: -115 do
            @preamble = para "", font: "Monospace 12px", stroke: silver, margin_left: 10
            @console = para "", font: "Monospace 13px", stroke: "#fff", wrap: "char", margin: [10,0,0,10]
            
            @entry = edit_line "", width: 0.9, margin: [10,10,0,10]
            @entry.finish = proc { |e| #@console.replace(@console.text, strong("#{e.text}\n"))
                                       puts e.text
                                       STDOUT.flush
                                       @history << e.text
                                       @pointer = @history.size-1
                                       e.text = ""
                                       @term.scroll_top = @term.scroll_max
                                  }
        end
    end
    
    def console() @console; end
    def entry() @entry; end
    def proc_names() @proc_names; end
    
    def launch_db_browser
        
        @proc_names = mute_get {puts "procs = gimp_procedural_db_query("+
                                    "'.*','.*','.*','.*','.*','.*','.*')[1]"}
                                    .match(RE_IRBRETURN)[1].gsub!(/"/, '')
                                    .split(", ").sort
        
        
        window title: "Procedural Database Browser", width: 800, height: 500 do
            style(Shoes::Link, underline: "none", stroke: black)
            style(Shoes::LinkHover, underline: "none", stroke: rgb(75,0,0), :fill => rgb(244,243,203))
            @style_bold = {weight: 'bold'}
            @procs = owner.proc_names
            @paramtypes = {"0"=>"INT32", "1"=>"INT16", "2"=>"INT8", "3"=>"FLOAT", 
                "4"=>"STRING", "5"=>"INT32ARRAY", "6"=>"INT16ARRAY", "7"=>"INT8ARRAY", 
                "8"=>"FLOATARRAY", "9"=>"STRINGARRAY", "10"=>"COLOR", "11"=>"ITEM", 
                "12"=>"DISPLAY", "13"=>"IMAGE", "14"=>"LAYER", "15"=>"CHANNEL", 
                "16"=>"DRAWABLE", "17"=>"SELECTION", "18"=>"COLORARRAY", "19"=>"VECTORS", 
                "20"=>"PARASITE", "21"=>"STATUS", "22"=>"END"}
            @proctypes = {"0"=>"internal", "1"=>"plugin", "2"=>"extension", "3"=>"temporary"}
            
            
            def build_proc(name, args, vals)
                pre = vals.each_with_object("") { |v,obj| obj << "#{v.gsub('-', '_')}, " }
                    .tap { |x| (x.slice!(-2..-1); x  << " = ") unless vals.empty? } 
                    .concat( "#{name.gsub('-', '_')}(" )
                
                args.each_with_object(pre) { |a,obj| obj << "#{a.gsub('-', '_')}, " }
                    .tap { |x| x.slice!(-2..-1) unless args.empty? } << ")"
            end
            
            def get_args(name, n_args, kind)
                (0...n_args).each_with_object({}) do |i,obj| 
                    ret = owner.mute_get { puts "gimp_procedural_db_proc_#{kind}('#{name}', #{i})" }
                    
                    ret.match(RE_IRBRETURN) do |m|
                        t, n, d = m[1].gsub!(/"/, '').split(", ")
                        obj[n] = [@paramtypes[t], d]
                    end
                end
            end 
            
            def show_proc(name)
                
                proc { @display.clear do
                    style(Shoes::Para, size: 11)
                    
                    blurb, help, auth, copyr, dat = owner.mute_get { 
                                puts "gimp_procedural_db_proc_info('#{name}')" }
                                .match(RE_IRBRETURN)[1].gsub('nil', '"nil"')
                                .match(RE_IRBRETURN_INFO)[1].split('", "')
                    type, n_args, nvals = $2, $3.to_i, $4.to_i
                    
                    flow margin: 0 do
                        @pname = para name, @style_bold.merge!(size: 12, margin: [0,6,20,5])
                        @try_button = custom_button("Try it !", swap_colors: true, marg_b: 10) {}
                    end
                    
                    inscription em("#{@proctypes[type]} procedure"), margin: [20,0,0,10]
                    
                    para blurb
                    
                    para "Parameters :  (#{n_args})", @style_bold
                    args = get_args(name, n_args, "arg")
                    args.each do |k,v|
                        para "#{v[0]}\t\t#{k}\t\t#{v[1]}"
                    end unless n_args == 0
                   
                    (para "Return Values :", @style_bold
                    vals = get_args(name, nvals, "val")
                    vals.each do |k,v|
                        para "#{v[0]}\t\t#{k}\t\t#{v[1]}"
                    end) unless nvals == 0
                    
                    @try_button.block = proc { owner.entry.text = build_proc(@pname.text, 
                                                                    args ? args.keys : [],
                                                                    vals ? vals.keys : []) 
                                               owner.entry.to_end }
                    
                    (para span("Additional information\n", @style_bold), help) unless help == blurb
                    (para span("Author : ", @style_bold), auth) unless auth == "nil"
                    (para span("Copyright : ", @style_bold), copyr) unless copyr == "nil"
                    (para span("Date : ", @style_bold), dat) unless dat == "nil"
                    
                    style(Shoes::Para, size: 12)
                end }
            end
            
            # not a good idea
            #proc_names = owner.proc_names.each_with_object({}) { |prn,obj| 
            #                    obj[prn] = link(prn.strip, click: show_proc(prn)) }
            
            background rgb(240,245,240)
            
            stack left: 0, top: 0, width: 300, height: self.height, attach: Shoes::Window do
                @search = edit_line("", width: 290, margin: [5,5,0,5]) { |e| 
                    @listing.clear do
                        background rgb(250,252,250)
                        @procs.each { |prn|
                            (check_proc = show_proc(prn)
                              para link(prn.strip, click: check_proc), margin:[0,2,0,2]
                              #para proc_names[prn], margin:[0,2,0,2]
                            ) if prn.match(e.text) } 
                    end
                    @listing.contents[0].height = @listing.scroll_height }
                
                @listing = stack margin: 5, height: self.height-30, scroll: true do
                    background rgb(250,252,250)
                    para span(@procs.join("\n"))
                    
                    start { |slf| bkg.height = slf.scroll_height }
                end
                
                start { @search.focus }
            end
            
            @display = stack width: 1.0, margin: [315,15,10,5] do
                para "search for procedures by typing into the edit line"
            end
            
        end
    end
    
    
    def get_input
        starting = true
        @irb_read_loop = animate(10) do
            begin
                outbuf = STDIN.read_nonblock(BUFFERSIZE)
                
                if starting # do this only once
                    outbuf =~ /^#+\s+(Irb.+-[\d\.]+)$\s(.+)\s(^[\d\.]+ :.+>.?)?/m
                    pt, ct = $2.to_s, $3.to_s # why ?????
                    @side.text = $1
                    @preamble.text = pt
                    @console.text = ">> " << ct
                    starting = false
                else
                    ((@console.text = @console.text + outbuf + ">> ") &&
                        @term.scroll_top = @term.scroll_max) unless @background_task
                end
                outbuf
                
            rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable => e
                #IO.select([STDIN])
                #retry
                nil
            rescue EOFError
                @console.replace(@console.text, span("\nConnection with Gimp is lost ...", stroke: orange))
                STDOUT.close
                @irb_read_loop.stop
            end
        end
    end
    
    # works without any terminal (ie : Gimp not launched from terminal)
    def mute_get(buffsize = BUFFERSIZE, &block)
        @irb_read_loop.stop
        @background_task = true
        yield
        # consume our request, we know we have something to read
        STDOUT.flush; STDIN.gets
        # get reply from irb, we know we have something to read
        STDOUT.flush
        outbuf = STDIN.gets
        
        # wait to consume irb's echo, takes some unpredictable time
        r1 = animate(5) do
            begin
                STDIN.read_nonblock(buffsize)
                #info "mute_get_loop : #{outbuf}"
                r1.stop
            rescue Errno::EAGAIN, Errno::EWOULDBLOCK, IO::WaitReadable => e
                #info "rescue mute_get_loop : #{e.message}"
                nil
            rescue EOFError
                @console.replace(@console.text, span("\nConnection with Gimp is lost ...", stroke: orange))
                STDOUT.close
                r1.remove
            ensure
                # make sure Timer is not prowling around
                r1.remove
                @background_task = false
                @irb_read_loop.start
            end
        end
        
        outbuf
    end
    
    
    start { @entry.focus; get_input }
    
    
end
