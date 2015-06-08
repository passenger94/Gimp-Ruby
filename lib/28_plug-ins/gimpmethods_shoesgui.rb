
require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu

Shoes.app :width => 322, :height => 610, :title => "Introspector" do
    
    #catch params from Gimp
    @gimp = gimp_says
    
    def ask_gimp(metod, args)
        newdata = super(metod, args)
        info newdata.inspect
        
        if metod == "EnumNames.constants"
            toc = newdata.sort.inject([]) {|r,el| r << link(el, :click => proc{check_enum(el)}) << "\n"}
            toc.pop
            @newdata = span(*toc)
        elsif metod == "EnumNames.const_get"
            @newdata = newdata.sort.shift
        else
            # don't sort 'ancestors', keep hierarchy
            newdata = metod.split(".")[1] == 'ancestors' ? newdata : newdata.sort
            @newdata = newdata.join("\n")
        end
        return @newdata
    end
    
    @currentTab = 0
    @items = [
        ["instance_methods",true],
        ["singleton_methods",true],
        ["methods"],
        ["public_methods",true],
        ["private_methods", true],
        ["protected_methods", true],
        ["private_instance_methods", true],
        ["protected_instance_methods", true],
        ["public_instance_methods", true],
        ["ancestors"],
        ["included_modules"],
        ["class_variables"],
        ["constants"]
    ].map { |i| i[1] ? [i[0] + " false", i[0] + " true"] : [i[0]] }.flatten
    
    
    def s2bool(str)
        str == "true" ? true : (str == "false" ? false : nil)
    end
    
    def set_clipboard(str)
        self.clipboard = str
    end
    
    
    background rgb(221,230,221)..rgb(101,133,101)
    
    flow :margin => 0 do
        background rgb(221,230,221)..rgb(101,133,101)
        para "Dive into gimp", :align => "center", :margin => [0,0,0,5]
    end
    
    flow do
        @tabs = ["methods","String constants","Numeric constants"].each_with_object([]) do |name,obj|
            tab = flow :width => 107 do
                background rgb(221,230,221)..rgb(101,133,101), :angle => 270
                inscription name, :size => 8, :margin => [5,5,0,4]
                name == "methods" ? border(orange) : border(rgb(101,133,101))
            end
            tab.click do
                @currentTab = @tabs.index(tab)
                clear_results_area(@currentTab)
                @res.replace ""
                @tabs.each do |tb|
                    #tb.contents.select {|e| e.is_a?(Shoes::Border)}[0].remove
                    tb.contents.last.remove
                    tb.append { border(tb == tab ? orange : rgb(101,133,101)) }
                end
            end
            obj << tab
        end
    end
    
    stack do
        flow :margin => 3 do
            @results_area = stack :width => 200
            
            button "check", :right => gutter, :margin_top => 2 do
                obj = @lookup.text
                met = @meth.text
                if @currentTab == 0
                    a = met.split(" ")
                    m, args = "#{obj}.#{a[0]}", s2bool(a[1])
                else
                    m, args = "Gimp.const_get", obj 
                end
                
                @res.replace ask_gimp(m,args)
            end
        end
        flow  :margin => [5,0,0,5], :height => 461, :scroll => true do
            @res = inscription ""
        end
    end
    
    flow :margin => 0 do
        background rgb(101,133,101)..rgb(221,230,221)
        inscription link("Enum Types", :click => proc{@res.replace(ask_gimp("EnumNames.constants",nil))}),
                                :margin => [20,13,0,0]
        @b = button "Quit", :right => gutter, :margin => 3 do
            tell_gimp "cancelled"
            exit
        end
    end
    
    def check_enum(enumtype)
        newdata = ask_gimp("EnumNames.const_get", enumtype)
        
        window :width => 300, :height => 400 do
            
            background rgb(221,230,221)..rgb(101,133,101)
            stack do
                inscription "click Enum to copy it to the clipboard ", :stroke => rgb(230,9,230)
                para enumtype, :align => "center"
                            #[["0", "IMAGE_CLONE"], ["1", "PATTERN_CLONE"]]
                acc = newdata.sort {|a,b| a[0].to_i <=> b[0].to_i}.each_with_object([]) do |el,obj|
                    obj << link(el[1], :click => proc{ self.clipboard = el[1] })
                    obj  << "   =>  #{el[0]}" << "\n"
                end
                
                acc.pop
                inscription span(*acc)
                button("close", :margin_left => 200) { close }
            end
        end
    end
    
    def clear_results_area(thetab)
        @results_area.clear do
            if thetab == 0
                @lookup = list_box :items => @gimp["gobj"], :choose => @gimp["gobj"].first
                @meth = list_box :items => @items, :choose => @items.first, :width => 200
            else
                its = thetab == 1 ? @gimp["string"] :  @gimp["numeric"]
                @lookup = list_box :items => its, :choose => its.first
                
                @meth = para "get constant value    >>>", :width => 200, :margin => [25,2,2,3]
            end
        end
    end
    
    clear_results_area(0)
    
end
