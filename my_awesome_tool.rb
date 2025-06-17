# my_awesome_tool_extension.rb
# วางไฟล์นี้ไว้ในโฟลเดอร์ Plugins ของ SketchUp

module MyAwesomeTool
  # คลาสสำหรับเครื่องมือสร้างสี่เหลี่ยม 3 มิติพร้อมเส้นนำทาง
  class RectangleTool

    # Constructor: Initializes instance variables
    def initialize
      @first_input_point = nil
      @second_input_point = nil
      @state = 0 # 0: waiting for first click, 1: waiting for second click
      @rectangle_height = nil # ความสูงของกำแพง (จาก InputBox)
      @rectangle_depth = nil  # ความหนาของกำแพง (จาก InputBox)
      @guide_line_start_pt = nil # จุดเริ่มต้นของเส้นนำทาง
      @mouse_down_state_0_x = nil # ใช้เก็บ x,y ของ onLButtonDown ใน state 0
      @mouse_down_state_0_y = nil # เพื่อตรวจสอบว่ามีการลากหรือไม่
      @current_mouse_position = nil # เก็บตำแหน่งเมาส์ปัจจุบันเพื่อวาดเส้นนำทาง
    end

    # เมธอด activate จะถูกเรียกเมื่อเครื่องมือถูกเลือก
    def activate
      @first_input_point = Sketchup::InputPoint.new
      @second_input_point = Sketchup::InputPoint.new
      @state = 0 # รีเซ็ตสถานะทุกครั้งที่เปิดเครื่องมือ
      @guide_line_start_pt = nil
      @mouse_down_state_0_x = nil
      @mouse_down_state_0_y = nil
      @current_mouse_position = nil
      prompt_for_dimensions
      update_ui
      Sketchup.active_model.active_view.invalidate
      puts "Debug: Tool Activated. State: #{@state}"
    end

    # เมธอด deactivate จะถูกเรียกเมื่อเครื่องมือถูกยกเลินการใช้งาน
    def deactivate(view)
      view.invalidate
      @first_input_point.clear if @first_input_point
      @second_input_point.clear if @second_input_point
      @guide_line_start_pt = nil
      @mouse_down_state_0_x = nil
      @mouse_down_state_0_y = nil
      @current_mouse_position = nil
      Sketchup.status_text = ""
      puts "Debug: Tool Deactivated. State: #{@state}"
    end

    # เมธอด onLButtonDown จะถูกเรียกเมื่อกดปุ่มเมาส์ซ้าย
    def onLButtonDown(flags, x, y, view)
      puts "Debug: onLButtonDown called. Current State: #{@state}"
      unless @rectangle_height && @rectangle_depth &&
             @rectangle_height > 0 && @rectangle_depth > 0
        UI.messagebox("Please enter valid positive dimensions for Height and Depth first.")
        onCancel(0, view)
        return
      end

      if @state == 0
        @first_input_point.pick(view, x, y)
        if @first_input_point.valid?
          @guide_line_start_pt = @first_input_point.position
          @mouse_down_state_0_x = x
          @mouse_down_state_0_y = y
          puts "Debug: State 0 - First point clicked (LButtonDown). Point: #{@guide_line_start_pt.inspect}"
        else
          UI.messagebox("Invalid first point. Please click on a valid location.")
          onCancel(0, view)
        end
      elsif @state == 1
        puts "Debug: onLButtonDown called in State 1. Waiting for second click release (no action)."
      end
      update_ui
    end

    # เมธอด onLButtonUp จะถูกเรียกเมื่อปล่อยปุ่มเมาส์ซ้าย
    def onLButtonUp(flags, x, y, view)
      puts "Debug: onLButtonUp called. Current State: #{@state}"

      if @state == 0
        if @guide_line_start_pt
          if @mouse_down_state_0_x && @mouse_down_state_0_y &&
             (x - @mouse_down_state_0_x).abs < 2 &&
             (y - @mouse_down_state_0_y).abs < 2
            
            @state = 1
            # *** จุดที่แก้ไข: กำหนดค่าเริ่มต้นให้ @current_mouse_position ทันที
            @current_mouse_position = @guide_line_start_pt.clone 
            puts "Debug: State 0 -> 1. First click completed. Setting current_mouse_position to first point. Waiting for second click."
          else
            UI.messagebox("Please click (not drag) for the first point.")
            onCancel(0, view)
          end
        else
          onCancel(0, view)
        end
      elsif @state == 1
        if @guide_line_start_pt
          @second_input_point.pick(view, x, y, @first_input_point)
          
          if !@second_input_point.valid?
            UI.messagebox("Invalid second point. Please click on a valid location.")
            onCancel(0, view)
            return
          end

          @guide_line_end_pt = @second_input_point.position
          puts "Debug: onLButtonUp - Second click completed. Guide line end point: #{@guide_line_end_pt.inspect}"

          model = Sketchup.active_model
          entities = model.active_entities

          model.start_operation("Create 3D Rectangle along Line", true)

          begin
            unless @guide_line_start_pt.is_a?(Geom::Point3d) && @guide_line_end_pt.is_a?(Geom::Point3d)
              UI.messagebox("Guide line points are invalid or nil. Please try again.")
              puts "Debug: @guide_line_start_pt is nil? #{@guide_line_start_pt.nil?}"
              puts "Debug: @guide_line_end_pt is nil? #{@guide_line_end_pt.nil?}"
              raise "Invalid guide line points or nil"
            end

            line_vector = @guide_line_end_pt - @guide_line_start_pt
            
            tolerance = 0.001.mm 
            
            if line_vector.length < tolerance
              UI.messagebox("Guide line is too short. Please draw a longer line. (Length: #{Sketchup.format_length(line_vector.length)})")
              puts "Debug: line_vector length: #{line_vector.length}. Raising error for short line."
              raise "Zero or near-zero length line vector"
            end
            
            xaxis = line_vector.normalize
            line_length = line_vector.length
            puts "Debug: Calculated line_length: #{Sketchup.format_length(line_length)}"
            puts "Debug: Xaxis (line direction) = #{xaxis.inspect}, length = #{xaxis.length}"

            model_zaxis = model.axes.zaxis.normalize
            model_xaxis = model.axes.xaxis.normalize
            model_yaxis = model.axes.yaxis.normalize
            
            yaxis = nil
            zaxis = nil

            if xaxis.parallel?(model_zaxis)
              puts "Debug: Xaxis is parallel to model Z-axis (vertical line)."
              
              temp_yaxis = model_xaxis 
              if temp_yaxis.parallel?(xaxis) || temp_yaxis.length < tolerance
                  temp_yaxis = model_yaxis 
              end
              
              if temp_yaxis.parallel?(xaxis) || temp_yaxis.length < tolerance
                  UI.messagebox("Could not determine a suitable Y-axis for vertical guide line. Please ensure model axes are standard.")
                  raise "Cannot determine Y-axis for vertical line"
              end
              
              yaxis = temp_yaxis.normalize
              temp_zaxis = xaxis.cross(yaxis)
              if temp_zaxis.length < tolerance
                UI.messagebox("Error determining Z-axis for vertical line. Possible collinearity issue.")
                raise "Error determining Z-axis for vertical line."
              end
              zaxis = temp_zaxis.normalize
              
            else
              puts "Debug: Xaxis is not parallel to model Z-axis (non-vertical line)."
              
              yaxis = model_zaxis 
              temp_zaxis = xaxis.cross(yaxis)
              
              if temp_zaxis.length < tolerance
                  UI.messagebox("Internal error: Z-axis calculation resulted in zero length for non-vertical line. This can happen if the line lies perfectly on the world XY plane and Y-axis is defined as Z-axis.")
                  
                  yaxis_candidate = Geom::Vector3d.new(-xaxis.y, xaxis.x, 0)
                  if yaxis_candidate.length < tolerance
                      UI.messagebox("Critical error: Cannot determine orthogonal Y-axis for non-vertical line.")
                      raise "Critical error: Cannot determine orthogonal Y-axis for non-vertical line."
                  end
                  yaxis = yaxis_candidate.normalize
                  zaxis = model_zaxis.normalize 
                  
                  puts "Debug: Adjusted yaxis to #{yaxis.inspect} (planar) and zaxis to #{zaxis.inspect} (model Z) due to collinearity."
              else
                  zaxis = temp_zaxis.normalize
              end
            end

            unless yaxis && yaxis.length > tolerance && zaxis && zaxis.length > tolerance
              UI.messagebox("Error: Final Y or Z axis is invalid after calculation.")
              puts "Debug: Final yaxis length: #{yaxis&.length}, Final zaxis length: #{zaxis&.length}"
              raise "Invalid final axes after calculation"
            end

            puts "Debug: Final xaxis (length direction) = #{xaxis.inspect}"
            puts "Debug: Final yaxis (height direction) = #{yaxis.inspect}"
            puts "Debug: Final zaxis (depth direction) = #{zaxis.inspect}"
            puts "Debug: Guide line start point for transform: #{@guide_line_start_pt.inspect}"

            transform = Geom::Transformation.axes(@guide_line_start_pt, xaxis, yaxis, zaxis)
            puts "Debug: Transformation created: #{transform.inspect}"

            points_local = [
              Geom::Point3d.new(0, 0, 0),
              Geom::Point3d.new(line_length, 0, 0), 
              Geom::Point3d.new(line_length, @rectangle_height, 0), 
              Geom::Point3d.new(0, @rectangle_height, 0) 
            ]
            puts "Debug: points_local: #{points_local.inspect}"

            points_global = points_local.map { |pt| pt.transform(transform) }
            
            puts "Debug: points_global for face creation: #{points_global.inspect}"

            unless points_global.is_a?(Array) && points_global.length == 4 && points_global.all? { |pt| pt.is_a?(Geom::Point3d) }
                UI.messagebox("Error: Invalid points generated for face creation.")
                raise "Invalid points for face creation"
            end
              
            unique_points = []
            points_global.each do |pt|
                unless unique_points.any? { |p| p.distance(pt) < tolerance } 
                    unique_points << pt
                end
            end

            if unique_points.length < 3
                UI.messagebox("Error: Not enough unique points to create a face. Points might be too close or collinear.")
                puts "Unique points for face creation: #{unique_points.inspect}"
                raise "Not enough unique points"
            end

            face = entities.add_face(points_global)

            if face && face.valid?
              if face.normal.dot(zaxis) < 0 
                face.reverse!
              end

              if @rectangle_depth && @rectangle_depth > 0
                face.pushpull(@rectangle_depth)
              else
                UI.messagebox("Depth is zero or negative. No pushpull performed.")
              end
            else
              UI.messagebox("Failed to create face. Points might be collinear or not coplanar. Check Ruby Console for details.")
              puts "Points for face creation: #{points_global.inspect}"
            end
          rescue => e
            UI.messagebox("An error occurred during rectangle creation: #{e.message}")
            puts "Error in rectangle creation: #{e.message}\n#{e.backtrace.join("\n")}"
          ensure
            model.commit_operation
          end

          @state = 0
          @first_input_point.clear
          @second_input_point.clear
          @guide_line_start_pt = nil
          @mouse_down_state_0_x = nil
          @mouse_down_state_0_y = nil
          @current_mouse_position = nil
          update_ui
        else
          puts "Debug: onLButtonUp called in State 1 but @guide_line_start_pt is nil. No action."
        end
      else
        puts "Debug: onLButtonUp called in unexpected State: #{@state}. No action taken."
      end
      view.invalidate
    end

    # เมธอด onMouseMove จะถูกเรียกเมื่อเมาส์เคลื่อนที่
    def onMouseMove(flags, x, y, view)
      if @state == 0
        @first_input_point.pick(view, x, y)
        view.tooltip = @first_input_point.tooltip if @first_input_point.valid?
      elsif @state == 1
        @second_input_point.pick(view, x, y, @first_input_point)
        # อัปเดตตำแหน่งเมาส์ปัจจุบัน ไม่ว่าจะ valid หรือไม่ก็ตาม
        @current_mouse_position = view.screen_to_model(x, y) 

        if @guide_line_start_pt && @second_input_point.valid?
          puts "Debug: onMouseMove in State 1. Drawing guide line from #{@guide_line_start_pt} to #{@second_input_point.position}"
          current_length = @guide_line_start_pt.distance(@second_input_point.position)
          view.tooltip = "Length: #{Sketchup.format_length(current_length)}"
        else
          # ใช้ตำแหน่งเมาส์ปัจจุบันสำหรับ tooltip หาก InputPoint ไม่ valid
          current_length = @guide_line_start_pt && @current_mouse_position ? @guide_line_start_pt.distance(@current_mouse_position) : 0
          view.tooltip = "Length: #{Sketchup.format_length(current_length)}"
          puts "Debug: onMouseMove in State 1. Guide line not drawn via InputPoint. Valid first: #{@first_input_point&.valid?}, Valid second: #{@second_input_point&.valid?}"
        end
      end
      view.invalidate 
      update_ui
    end

    # เมธอด draw จะถูกเรียกทุกครั้งที่ View ถูก Refresh เพื่อวาดสิ่งต่างๆ
    def draw(view)
      @first_input_point.draw(view) if @first_input_point && @first_input_point.valid?
      
      # วาดเส้นนำทางเสมอเมื่ออยู่ใน state 1 และมีจุดเริ่มต้นแล้ว
      if @state == 1 && @guide_line_start_pt && @current_mouse_position
        puts "Debug: Draw called in State 1. Drawing guide line using current mouse position. Start: #{@guide_line_start_pt}, End: #{@current_mouse_position}"
        view.set_color_material([0, 0, 0]) 
        view.line_width = 1
        view.line_stipple = "" 
        view.draw(GL_LINES, @guide_line_start_pt, @current_mouse_position) # ใช้ @current_mouse_position ที่ได้จาก onMouseMove
      else
        puts "Debug: Draw called. Guide line not drawn. State: #{@state}, First Pt Valid: #{@first_input_point&.valid?}, Current Mouse Position: #{@current_mouse_position.inspect}"
      end
      @second_input_point.draw(view) if @second_input_point && @second_input_point.valid? # วาด inference point ถ้ามี
    end

    # เมธอด onSetCursor จะถูกเรียกเมื่อ SketchUp ต้องการตั้งค่า Cursor
    def onSetCursor
      UI.set_cursor(632) 
      true 
    end

    # เมธอด onCancel จะถูกเรียกเมื่อผู้ใช้กด ESC
    def onCancel(reason, view)
      @state = 0
      @first_input_point.clear if @first_input_point
      @second_input_point.clear if @second_input_point
      @guide_line_start_pt = nil
      @mouse_down_state_0_x = nil
      @mouse_down_state_0_y = nil
      @current_mouse_position = nil
      view.invalidate
      update_ui
      prompt_for_dimensions if reason == 0 
    end

    # เมธอดช่วยในการอัปเดตข้อความในแถบสถานะ
    def update_ui
      if !@rectangle_height || !@rectangle_depth ||
         @rectangle_height <= 0 || @rectangle_depth <= 0
        Sketchup.status_text = "Please enter valid positive dimensions for Height and Depth in the pop-up window."
      else
        height_text = Sketchup.format_length(@rectangle_height)
        depth_text = Sketchup.format_length(@rectangle_depth)

        case @state
        when 0
          Sketchup.status_text = "Click to set the first point of the guide line for a wall with Height: #{height_text}, Depth: #{depth_text}."
        when 1
          current_length = @guide_line_start_pt && @current_mouse_position ? @guide_line_start_pt.distance(@current_mouse_position) : 0
          Sketchup.status_text = "Click to set the second point of the guide line. Current Length: #{Sketchup.format_length(current_length)}"
        end
      end
    end

    # เมธอดสำหรับแสดง InputBox เพื่อรับขนาด (ตอนนี้เหลือแค่ Height และ Depth)
    @@last_entered_height = nil
    @@last_entered_depth = nil

    def prompt_for_dimensions
      @@last_entered_height ||= 2500.mm 
      @@last_entered_depth ||= 100.mm  

      height_display = Sketchup.format_length(@@last_entered_height)
      depth_display = Sketchup.format_length(@@last_entered_depth)

      prompts = ["Height (Vertical):", "Depth (Thickness):"]
      defaults = [height_display, depth_display]
      results = UI.inputbox(prompts, defaults, "Enter Wall Dimensions")

      if results 
        temp_height = Sketchup.parse_length(results[0])
        temp_depth = Sketchup.parse_length(results[1])

        if temp_height && temp_height > 0 && temp_depth && temp_depth > 0
          @rectangle_height = temp_height
          @rectangle_depth = temp_depth

          @@last_entered_height = @rectangle_height
          @@last_entered_depth = @rectangle_depth

          Sketchup.status_text = "Click to set the first point of the guide line for a wall with Height: #{Sketchup.format_length(@rectangle_height)}, Depth: #{Sketchup.format_length(@rectangle_depth)}."
        else
          UI.messagebox("Height and Depth must be positive numeric values. Please try again.")
          Sketchup.active_model.tools.pop_tool
          Sketchup.status_text = ""
        end
      else 
        Sketchup.active_model.tools.pop_tool
        UI.messagebox("Wall creation tool cancelled.")
        Sketchup.status_text = ""
        @rectangle_height = nil
        @rectangle_depth = nil
      end
    end

  end # class RectangleTool

  # ตั้งค่าเมนูและแถบเครื่องมือสำหรับเรียกใช้เครื่องมือ
  unless file_loaded?(__FILE__)
    menu = UI.menu("Tools")
    menu.add_item("My Wall Tool Along Line") { Sketchup.active_model.select_tool(RectangleTool.new) }

    toolbar = UI::Toolbar.new("My Awesome Tools")
    cmd = UI::Command.new("My Wall Tool Along Line") { Sketchup.active_model.select_tool(RectangleTool.new) }
    cmd.tooltip = "Create a wall by drawing its base line, then defining Height and Thickness."
    cmd.small_icon = File.join(__dir__, "images", "wall_tool_small.png") 
    cmd.large_icon = File.join(__dir__, "images", "wall_tool_large.png") 
    toolbar.add_item(cmd)
    toolbar.show

    file_loaded(__FILE__)
  end

end # module MyAwesomeTool