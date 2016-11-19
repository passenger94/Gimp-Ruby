
TYPESPARAMDEF = [
    "none", 
    "ENUM", 
    "SLIDER", 
    "SPINNER", 
    "TOGGLE",
    "STRING", 
    "FLOAT", 
    "INT32",
    "LIST",
    "COLOR",
    "BRUSH", 
    "PATTERN", 
    "GRADIENT", 
    "PALETTE",
    "TEXT",
    "DIR", 
    "FILE", 
    "FONT",
    "DRAWABLE", 
    "CHANNEL", 
    "LAYER", 
    "IMAGE", 
    "PARASITE",
    "STRINGARRAY", 
    "FLOATARRAY",
    "INT8ARRAY", 
    "INT16ARRAY", 
    "INT32ARRAY",
    "INT8", 
    "INT16"
]

IMAGETYPES = [
    "*",
    "RGB*",
    "RGB",
    "RGBA", 
    "GREY*",
    "GREY",
    "GREYA",
    "INDEXED*",
    "INDEXED",
    "INDEXEDA",
    "nil"
]

MENUPATHS = [
    "<Image>/File/Create/RubyFu/", 
    '<Image>/Filters/Ruby-Fu_Toolbox/',
    "<Image>/Fus/Ruby-Fu/",
    "<Layers>", "<Channels>", "<Vectors>", "<Brushes>", "<Gradients>", "<Palettes>", "<Patterns>",
    "<ToolPresets>", "<Dynamics>", "<Fonts>", "<Buffers>", "<Colormap>", 
    "<NoMenu>"
]

class Shoes::LabelEdit < Shoes::Widget
    attr_reader :wedit_line, :wlabel
    
    def initialize(label_text, edit_text = "", widget_width=1.0)
        self.width = widget_width
        @label_text = label_text
        @wtext = edit_text
        
        flow width: 120 do
            @wlabel = para @label_text
        end
        flow width: -121 do
            @wedit_line = edit_line @wtext
        end
    end
    
    def wtext; @wedit_line.text; end
    def wtext= t; @wedit_line.text= t; end
    
end

Shoes.app :title => "New ruby-fu", :width => 940, :height => 500 do
 
Image_help = [strong("name"), " : the variable name assigned to the parameter\n",
strong("label"), " : the description of the element used in the graphic user interface"]

List_help = [Image_help, 
"\n", strong("list")," : an array of String elements to populate a list box widget
\t enter elements separated by a ',' "]
    
Enum_help = [Image_help,
"\n", strong("default")," : a default <Integer> value for the parameter",
"\n\tthe value <Integer> of the element in the given EnumType list\n",
strong("enum"), " : a Gimp::EnumNames Type (like ", em("ImageBaseType"),") <String>"]
    
Spinner_help = [Image_help,
"\n", strong("default")," : a default <Integer> value for the parameter\n",
strong("range")," : a ruby Range Objet (ie : 0..100 )\n",
strong("step")," : <Integer> is the amount of change when clicking on the widget bar"]

bold_red = {:weight => "bold", :stroke => red}
Default_help = [Image_help, 
    "\n", strong("default")," : default value for the parameter (", em("depending on the type of parameter"), ")",
    "\n\tfor TOGGLE : enter 0 or 1 (false or true)", "\n\tfor Arrays : enter elements separated by a ','",
    "\n\tfor TEXT : multiline text ie : ", em('a\nmultiline\ntext'),
    "\n\tfor COLOR : enter the 3 - r,g,b - float values (0.0 >= value <= 1.0) separated by a ','\n\n\t", 
    
    span("for PARASITE : enter 3 values separated by a '", strong(";"), "'", :stroke => red), "\n\t",
    strong(em("name")), " <String> ie: myparasite ", span(";", bold_red), " ", 
    strong(em("flags")), " <Integer> ie : 123 ", span(";", bold_red), " ", 
    strong(em("data")), " <String> ie : ['one', 1.0, 'two' ,235]",
    
    "\n\t\t strings inside ", strong(em("data")), " should be entered with '", em("single quotes"), 
    "' ", span("not", :underline => 'single'), " \"", em("double quotes"), "\" ie : 'astring' "
]

    Style_font_preview = {font: 'Monospace', size: 10}
    
    
    def pop_help(title, text)
        window :title => "#{title}", :width => 750, :height => 310 do
            stack :margin => 10 do
                para span(*text)
            end
        end
    end
    
    def populate_row(listbox_text)
        labels = ["name","label"]
        case listbox_text
            when "IMAGE", "LAYER", "CHANNEL", "DRAWABLE"
                text = Image_help
            when "LIST"
                labels += ["list"]
                text = List_help
            when "ENUM"
                labels += ["default", "enum"]
                text = Enum_help
            when "SPINNER", "SLIDER"
                labels += ["default", "range", "step"]
                text = Spinner_help
            else 
                labels += ["default"]
                text = Default_help
        end
        
        labels.each do |label|
            para label
            edit_line "", :width => 110
        end
        
        flow :width => 40, :margin_left => 5 do
           fill black
           oval 3, 0, 26
           click { pop_help(listbox_text, text) }
           inscription "help", :stroke => white 
        end
    end
    
    def add_paramdef
        @paramdef.append do
            flow do
                list_box :items => TYPESPARAMDEF, :choose => "none", :width => 120 do |list|
                    list.parent.contents[1..-1].each {|el| el.remove}
                    list.parent.append { populate_row(list.text) }
                end
            end
        end
    end
    
    def del_paramdef
        @paramdef.contents.last.remove
    end
    
    def do_paramdef
        return ["[]",""] if @paramdef.contents.empty?
        
        @toggles = []
        indent = "\n            "
        result = ["[#{indent}", ""]
        
        @paramdef.contents.each do |fl|
            f = fl.contents
            # f[0]--> ParamDef type, f[2]--> argument name, f[4]--> gui label
            # f[6]--> default value, f[8]--> array/range, f[10]--> step
            result[0] << "ParamDef.#{f[0].text}('#{f[2].text}', '#{f[4].text}'"
            
            if f[0].text == "none"
                result[0] = "[,#{indent}"
            else
                result[0] << case f[0].text
                    when "IMAGE",	"LAYER", "CHANNEL",	"DRAWABLE"
                         ")"
                    when "INT32", "INT16",	"INT8",	"FLOAT", "TOGGLE"
                        @toggles << f[2].text if f[0].text == "TOGGLE"
                        ", #{f[6].text})"
                    when "TEXT", "BRUSH", "PATTERN", "GRADIENT", "PALETTE", "DIR", "FILE", "FONT", "STRING"
                        ", \"#{f[6].text}\")"
                    when "ENUM"
                        ", #{f[6].text}, '#{f[8].text}')"
                    when "SPINNER", "SLIDER"
                        ", #{f[6].text}, #{f[8].text}, #{f[10].text})"
                    when "INT32ARRAY", "INT16ARRAY", "FLOATARRAY"
                        ", [#{f[6].text}])"
                    when "COLOR"
                        ", Color(#{f[6].text}))"
                    when "LIST", "STRINGARRAY"
                        prm = f[6].text.split(",").map{|e| e.strip}.inspect
                        ", #{prm})"
                    when "PARASITE"
                        name, flags, data = f[6].text.split(";")
                        prm = 'Gimp::Parasite.new(' + [ name.inspect, flags, data.inspect ].join(', ') + ')'
                        ", #{prm})"
                    when "INT8ARRAY"
                        ", \"#{f[6].text}\")" # INT8ARRAY implemented as a String
                end  << ",#{indent}"
                
                result[1] << ", #{f[2].text}"
            end
        end
        result[0][-14..-1] = "#{indent}        ]" # closing bracket, get rid of last coma and one 4 spaces
        result
    end
    
    
    ## UI
    background rgb(242,241,240)
    stack margin_left: 10 do
        flow do
            stack width: 730, margin: 10 do
                flow margin: [0,10,0,20] do
                    para "ruby file : "
                    @file = edit_line "", :width => 500
                    button("browse") { @file.text = ask_save_file }
                end
                
                flow do
                    @fonction = label_edit "function name : ", "", 330
                    @fonction.wedit_line.style width: 200
                    inscription '"ruby-fu-" will be prepended to the name you provide'
                end
                
                flow do
                    @menulabel = label_edit "menu label : "
                end
                
                flow do
                    @menupath = label_edit "menu path : ", MENUPATHS[2], 420
                    @menupath.wedit_line.style width: 300, margin_right: 10
                    
                    list_box :items => MENUPATHS, :choose => MENUPATHS[2], :width => 270 do |list|
                        @menupath.wtext = list.text
                        @typewarn.text = ""
                        if /Toolbox|Create/ =~ list.text
                            @type.choose("nil")
                            @doDomain = "run_mode"
                            @results = "[ParamDef.IMAGE('image', 'Image')]"
                        else
                            @type.choose("*")
                            @doDomain = "run_mode, image, drawable"
                            @results = "[]"
                        end
                    end
                end
                
                flow do
                    para "image type : ", margin_right: 31
                    @type = list_box :items => IMAGETYPES, :choose => "*", :width => 120 do |list|
                        if /Toolbox|Create/ =~ @menupath.wtext
                            @typewarn.text = "Not a procedure usable in an Image context" if list.text != "nil"
                            @typewarn.text = "" if list.text == "nil" # after user corrected
                        else
                            if list.text == "nil"
                                @typewarn.text = "This procedure must be used in an Image context"
                            else
                                @typewarn.text = ""
                            end
                        end
                    end
                    @typewarn = para "", :stroke => red, :margin_left => 50
                end
                
                flow do
                    @blurb = label_edit "blurb : ", "...", 330
                    
                    @help = label_edit "help : ", "......", 380
                    @help.wlabel.style margin_left: 45
                    @help.wedit_line.style width: 300
                end
                
                flow do
                    @author = label_edit "author : ", "", 230
                    @author.wedit_line.style width: 120
                    
                    @copyr = label_edit "copyright : ", "", 230
                    @copyr.wlabel.style margin_left: 20
                    @copyr.wedit_line.style width: 120
                    
                    @date = label_edit "date : ", "", 230
                    @date.wlabel.style margin_left: 50
                    @date.wedit_line.style width: 120
                end
            end # stack
            
            stack :width => 180, :margin => [80,0,0,0] do
                button("Cancel", :margin => [0,150,0,20], :width => 80) {exit}
                button("Preview", :margin => [0,0,0,20], :width => 80) {preview_fu(create_fu)}
                button("OK", :width => 80) {write_fu(create_fu)}
            end
            
        end # flow
        
        stack :margin => [0,10,5,5] do
            stroke rgb(132,130,88)
            line 150, 0, 740, 0
            stroke rgb(239,205,159)
            line 150, 1, 740, 1
            para "Parameters"
            flow do
                button("add") {add_paramdef}
                button("del") {del_paramdef}
            end
            @paramdef = stack :margin => [0,10,0,0]
        end 
            
    end # main stack
    
    add_paramdef
    
    
    
    def create_fu
        params, vars = do_paramdef
        
        # convenience method translating gimp boolean into ruby boolean
        init_toggles = @toggles.empty? ? "" : @toggles.each_with_object(["\n\t"]) {|t,obj| obj << "\n\t#{t} = (#{t} == 1)"}.join
        
        actions, display = @doDomain == "run_mode" ? ['disable', ''] : ['group_start', 'Display.flush']
        
        code = "#!ruby

require 'rubyfu'
include RubyFu

RubyFu.register(
	:name       => 'ruby-fu-#{@fonction.wtext}',
	:blurb      => '#{@blurb.wtext}',
	:help       => '#{@help.wtext}',
	:author     => '#{@author.wtext}',
	:copyright  => '#{@copyr.wtext}',
	:date       => '#{@date.wtext}',
	:menulabel  => '#{@menulabel.wtext}',
	:imagetypes => '#{@type.text}',
	:params     =>  #{params},
	:results    =>  #{@results}

) do |#{@doDomain}#{vars}|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)#{init_toggles}
    #{@doDomain == "run_mode" ? "\n    image = Image.new(width, height, 0)\n    " : ""}
    Context.push do
        image.undo_#{actions} do
            
            message('ok -------')
            
        end # undo_#{actions}
    end # Context
    #{display}
end

RubyFu.menu_register('ruby-fu-#{@fonction.wtext}', '#{@menupath.wtext}')

"
    end # create_fu
    
    def preview_fu(code)
        window title: "Preview", height: 700, width: 600 do
            stack margin: 10 do
                para code, Style_font_preview
                
                flow left: 0, top: 0, height: 40, attach: Shoes::Window do
                    background rgb 0,0,0,0
                    button('Close Preview', margin: [400,5,0,0]) { close }
                end
                
            end
        end
    end
    
    def write_fu(code)
        begin
            File.open("#{@file.text}","w+", 0750) do |f|
                f.write(code)
            end
            exit
        rescue SystemCallError => e
            info e.backtrace*"\n"
            alert "#{e.message}\nPlease, i need a file to save code into ..."
        end
    end
    
end


