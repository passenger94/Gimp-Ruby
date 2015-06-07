
Shoes.app title: "Shoes Irb <-> Gimp console", width:800, height: 600 do
    BUFFERSIZE = 1024
    RE_IRBRETURN = /=>\s*\["?(.+)\]/
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
            @entry.to_end
            @entry.text = @history[@pointer]
        else
            
        end
    end
    
    
    background darkslategray
    
    flow width: 1.0 do
        stack width: 115, attach: Shoes::Window do
            @side = inscription "", stroke: silver
            
            button "Refresh", margin: [5,10,0,20] do
                mute_get { puts 'instance_variables.each {|iv|' +
                        'instance_variable_set(iv, nil) if iv.match(/layer\d+/) }' }
                t = mute_get(BUFFERSIZE, 2) { puts "load 'imageDrawable4console.rb'" }
                @preamble.text = t
            end
            
            button "Browse", margin: [5,10,0,20] do
                launch_db_browser
            end            
            
            button "Clear", margin: [5,10,0,20] do
                @console.text = ""
            end
            
            button "Save", margin: [5,10,0,20] do
                info "Save not implemented yet"
                #file = ask_save_file
            end
            
            button "Close", margin: [5,5,0,0] do
                puts "exit"  # irb
                STDOUT.flush
                exit
            end
        end    
        
        @term = stack width: -115 do
            @preamble = para "", font: "Monospace 12px", stroke: silver, margin_left: 10
            @console = para "", font: "Monospace 13px", stroke: "#fff", wrap: "char", margin: [10,0,0,10]
            
            @entry = edit_line "", width: 0.9, margin: [10,10,0,10]
            @entry.finish = proc { |e| @console.replace(@console.text, strong("#{e.text}\n"))
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
        
        @proc_names = mute_get(40960) {puts "procs = gimp_procedural_db_query("+
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
            
            
            def build_proc(name, args, vals)
                pre = vals.each_with_object("") { |v,obj| obj << "#{v.gsub('-', '_')}, " }
                    .tap { |x| (x.slice!(-2..-1); x  << " = ") unless vals.empty? } 
                    .concat("#{name.gsub('-', '_')}(")
                
                args.each_with_object(pre) { |a,obj| obj << "#{a.gsub('-', '_')}, " }
                    .tap { |x| x.slice!(-2..-1) unless args.empty? } << ")"
            end
            
            def get_args(name, n_args, kind)
                (0...n_args).each_with_object({}) do |i,obj| 
                    ret = owner.mute_get(4096) { puts "gimp_procedural_db_proc_#{kind}('#{name}', #{i})" }
                    
                    ret.match(RE_IRBRETURN) do |m|
                        t, n, d = m[1].gsub!(/"/, '').split(", ")
                        obj[n] = [@paramtypes[t], d]
                    end
                end
            end 
            
            def present(name)
                proc { @display.clear do
                    blurb, help, auth, copyr, dat = owner.mute_get(4096) { 
                                puts "gimp_procedural_db_proc_info('#{name}')" }
                                .match(RE_IRBRETURN)[1].gsub('nil', '"nil"')
                                .match(RE_IRBRETURN_INFO)[1].split('", "')
                    type, n_args, nvals = $2, $3.to_i, $4.to_i
                    
                    flow margin: 0 do
                        @pname = para name, @style_bold.merge!(margin: [0,6,20,5])
                        @try_proc = flow width: 75, height: 25 do
                            background darkslategray, curve: 5
                            para "Try it !", stroke: white, margin: [10,4,0,0]
                        end
                    end
                    
                    inscription em(
                        case type.to_i
                        when 0 then "internal procedure"
                        when 1 then "plugin procedure"
                        when 2 then "extension procedure"
                        when 3 then "temporary procedure"
                        end), margin: [20,0,0,10]
                    
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
                    
                    @try_proc.click { owner.entry.text = build_proc(@pname.text, 
                                                                    args ? args.keys : [],
                                                                    vals ? vals.keys : []) }
                        
                    (para span("Additional information\n", @style_bold), help) unless help == blurb
                    (para span("Author : ", @style_bold), auth) unless auth == "nil"
                    (para span("Copyright : ", @style_bold), copyr) unless copyr == "nil"
                    (para span("Date : ", @style_bold), dat) unless dat == "nil"
                    
                end }
            end
            
            #TODO build a hash :  owner.proc_names --> link(prn.strip, click: present(prn))
            
            background rgb(240,245,240)
            
            stack left: 0, top: 0, width: 300, height: self.height, attach: Shoes::Window do
                @search = edit_line("", width: 290, margin: [5,5,0,5]) { |e| 
                    @listing.clear do
                        @procs.each { |prn|
                            (check_proc = present(prn)
                              para link(prn.strip, click: check_proc), margin:[0,2,0,2]
                            ) if prn.match(e.text) } 
                    end }
                
                @listing = stack margin: 5, height: self.height-30, scroll: true do
                    background rgb(250,252,250)
                    para span(@procs.join("\n"))
                end
            end
            
            @display = stack width: 1.0, margin: [315,15,10,5] do
                para "search for procedures by typing into the edit line"
            end
            
            timer(0.5) { @search.focus }
        end
    end
    
    def get_input
        entered = false
        @irb_read_loop = animate(10) do
            begin
                outbuf = STDIN.read_nonblock(BUFFERSIZE)
                #outbuf = $stdin.gets
                unless entered # do this only once
                    outbuf =~ /^#+\s+(Irb.+-[\d\.]+)$\s(.+)\s(^[\d\.]+ :.+>.?)/m
                    pt, ct = $2.to_s, $3.to_s # why ?????
                    @side.text = $1
                    @preamble.text = pt
                    @console.text = ct
                    entered = true
                else
                    (@console.replace(@console.text, outbuf) &&
                        @term.scroll_top = @term.scroll_max) unless @background_task
                    
                end
                
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
    
    def mute(&block)
        @background_task = true
        yield
        
        # consume silently the reply from irb
        @irb_read_loop.stop
        STDOUT.flush
        r, = IO.select([STDIN])
        #while !r; end
        STDIN.read_nonblock(BUFFERSIZE)
        @irb_read_loop.start
        
        @background_task = false
    end
    
    def mute_get(buffsize = BUFFERSIZE, loops = 1, &block)
        @background_task = true
        yield
        
        @irb_read_loop.stop
        STDOUT.flush
        r, = IO.select([STDIN])
        #while !r; end
        out = STDIN.read_nonblock(buffsize)
        
        # consume silently the echo from irb # TODO make sure echo is turned on or process echo off
        loops.times {
            STDOUT.flush
            r, = IO.select([STDIN])
            #while !r; end
            STDIN.read_nonblock(BUFFERSIZE)
            @irb_read_loop.start
        }
        
        @background_task = false
        out
    end
    
    timer(0.5) { @entry.focus; get_input }
    
    
end
