# my_awesome_tool_extension.rb
# วางไฟล์นี้ไว้ในโฟลเดอร์ Plugins ของ SketchUp

module MyAwesomeTool
  # คลาสสำหรับเครื่องมือสร้างสี่เหลี่ยม 3 มิติพร้อมเส้นนำทาง
  class RectangleTool

    # Constructor: Initializes instance variables
    def initialize
      @first_input_point = nil
      @second_input_point = nil
      @state = 0 # 0: waiting for first click, 1: drawing guide line
      # @rectangle_width ถูกนำออกแล้ว ความยาวจะตามเส้นที่ลาก
      @rectangle_height = nil # ความสูงของกำแพง (จาก InputBox)
      @rectangle_depth = nil  # ความหนาของกำแพง (จาก InputBox)
      @guide_line_start_pt = nil # จุดเริ่มต้นของเส้นนำทาง
      @guide_line_end_pt = nil   # จุดสิ้นสุดของเส้นนำทาง (อัปเดตจากเมาส์ขณะลาก)
    end

    # เมธอด activate จะถูกเรียกเมื่อเครื่องมือถูกเลือก
    def activate
      @first_input_point = Sketchup::InputPoint.new
      @second_input_point = Sketchup::InputPoint.new
      @state = 0 # รีเซ็ตสถานะทุกครั้งที่เปิดเครื่องมือ
      @guide_line_start_pt = nil
      @guide_line_end_pt = nil

      prompt_for_dimensions # แสดง InputBox เพื่อรับ Height และ Depth เท่านั้น
      update_ui
      Sketchup.active_model.active_view.invalidate # บังคับให้หน้าจอวาดใหม่
    end

    # เมธอด deactivate จะถูกเรียกเมื่อเครื่องมือถูกยกเลิกการใช้งาน
    def deactivate(view)
      view.invalidate # ล้างการวาดชั่วคราว
      @first_input_point.clear if @first_input_point
      @second_input_point.clear if @second_input_point
      @guide_line_start_pt = nil
      @guide_line_end_pt = nil
      Sketchup.status_text = "" # ล้างข้อความสถานะ
    end

    # เมธอด onLButtonDown จะถูกเรียกเมื่อกดปุ่มเมาส์ซ้าย
    def onLButtonDown(flags, x, y, view)
      # ตรวจสอบว่าป้อนขนาด Height และ Depth แล้ว
      unless @rectangle_height && @rectangle_depth &&
             @rectangle_height > 0 && @rectangle_depth > 0
        UI.messagebox("Please enter valid positive dimensions for Height and Depth first.")
        onCancel(0, view) # ยกเลิกเครื่องมือ
        return
      end

      if @state == 0
        # คลิกแรก: กำหนดจุดเริ่มต้นของเส้นนำทาง
        @first_input_point.pick(view, x, y)
        if @first_input_point.valid?
          @guide_line_start_pt = @first_input_point.position
          @state = 1 # เปลี่ยนสถานะเป็นกำลังวาดเส้นนำทาง
          puts "Debug: State 0 -> 1. First point set to: #{@guide_line_start_pt.inspect}"
        else
          # ถ้าจุดแรกไม่ valid ให้ยกเลิกเครื่องมือ
          onCancel(0, view)
        end
      elsif @state == 1
        # คลิกที่สอง: กำหนดจุดสิ้นสุดของเส้นนำทาง
        @second_input_point.pick(view, x, y, @first_input_point)
        if @second_input_point.valid?
          @guide_line_end_pt = @second_input_point.position
          puts "Debug: State 1. Second point set to: #{@guide_line_end_pt.inspect}"
          # ไม่ต้องเปลี่ยน state เพราะ onLButtonUp จะถูกเรียกทันทีหลังจากนี้
        else
          # ถ้าจุดที่สองไม่ valid ให้ยกเลิกเครื่องมือ
          onCancel(0, view)
        end
      end
      update_ui
    end

    # เมธอด onLButtonUp จะถูกเรียกเมื่อปล่อยปุ่มเมาส์ซ้าย
    def onLButtonUp(flags, x, y, view)
      # การสร้างสี่เหลี่ยมจะเกิดขึ้นเมื่ออยู่ใน state 1 และผู้ใช้ปล่อยเมาส์หลังจากคลิกจุดที่สอง
      if @state == 1
        model = Sketchup.active_model
        entities = model.active_entities

        # เริ่ม Operation เพื่อให้สามารถ Undo ได้ในขั้นตอนเดียว
        model.start_operation("Create 3D Rectangle along Line", true)

        begin
          # ตรวจสอบให้แน่ใจว่าจุดนำทางมีค่า
          unless @guide_line_start_pt.is_a?(Geom::Point3d) && @guide_line_end_pt.is_a?(Geom::Point3d)
            UI.messagebox("Guide line points are invalid. Please try again.")
            raise "Invalid guide line points"
          end

          # คำนวณความยาวของเส้นนำทาง - นี่จะเป็น Width ของกำแพง
          line_length = @guide_line_start_pt.distance(@guide_line_end_pt)
          puts "Debug: Calculated line_length: #{Sketchup.format_length(line_length)}"
          
          if line_length < 0.001.mm # ความยาวน้อยกว่าเกณฑ์ที่กำหนด (เช่น 0.001 มม.)
            UI.messagebox("Guide line is too short. Please draw a longer line.")
            raise "Zero or near-zero length line vector" # ยกเลิกการทำงาน
          end
            
          line_vector = @guide_line_end_pt - @guide_line_start_pt
          # ตรวจสอบว่า line_vector ไม่เป็น Zero Vector ก่อน normalize
          if line_vector.length < 0.001.mm # ตรวจสอบอีกครั้ง
            UI.messagebox("Internal error: Line vector is still zero length after initial check.")
            raise "Zero length line vector before normalize"
          end
          
          # --- กำหนด X-axis (ทิศทางความยาว) เป็นทิศทางของเส้นนำทาง ---
          xaxis = line_vector.normalize
          puts "Debug: Xaxis (line direction) = #{xaxis.inspect}, length = #{xaxis.length}"

          # --- กำหนด Y-axis (ทิศทางความสูง) และ Z-axis (ทิศทางความหนา) ---
          model_zaxis = model.axes.zaxis.normalize # แกน Z ของโมเดล (โลก)
          model_xaxis = model.axes.xaxis.normalize # แกน X ของโมเดล (โลก)
          model_yaxis = model.axes.yaxis.normalize # แกน Y ของโมเดล (โลก)
          
          yaxis = nil
          zaxis = nil

          # ตรวจสอบว่าเส้นนำทางขนานกับแกน Z ของโลกหรือไม่
          # ใช้ .parallel? เพื่อตรวจสอบการขนานกัน ไม่ว่าจะเป็นทิศทางเดียวกันหรือตรงกันข้าม
          # SketchUp's .parallel? has a built-in tolerance
          if xaxis.parallel?(model_zaxis)
            puts "Debug: Xaxis is parallel to model Z-axis (vertical line)."
            # กรณีที่เส้นนำทางเป็นแนวตั้ง (ขนานกับ model_zaxis)
            # เราจะให้ yaxis เป็น model_xaxis (หรือ model_yaxis ถ้า model_xaxis ขนานกับ xaxis)
            # เพื่อให้ yaxis ตั้งฉากกับ xaxis และอยู่ในระนาบ XY ของโลกโดยประมาณ
            
            temp_yaxis = model_xaxis # เริ่มต้นด้วย model_xaxis
            
            # ตรวจสอบว่า temp_yaxis ไม่ขนานกับ xaxis (ซึ่งเป็นแนวตั้ง)
            if temp_yaxis.parallel?(xaxis)
                temp_yaxis = model_yaxis # ลองใช้ model_yaxis แทน
            end
            
            # หากยังขนานกัน แสดงว่าแกนโลกอาจผิดปกติ หรือเส้นนำทางอยู่บนแกนโลกพอดี
            if temp_yaxis.parallel?(xaxis)
                UI.messagebox("Could not determine a suitable Y-axis for vertical guide line. Please ensure model axes are standard.")
                raise "Cannot determine Y-axis for vertical line"
            end
            
            yaxis = temp_yaxis.normalize
            zaxis = xaxis.cross(yaxis).normalize # Z-axis จะตั้งฉากกับ X และ Y
            
          else
            puts "Debug: Xaxis is not parallel to model Z-axis (non-vertical line)."
            # กรณีทั่วไป: เส้นนำทางไม่ได้เป็นแนวตั้ง
            # เราต้องการให้ yaxis (ความสูง) ชี้ขึ้นตาม model_zaxis
            yaxis = model_zaxis 
            
            # zaxis (ความหนา) จะตั้งฉากกับ xaxis (เส้นนำทาง) และ yaxis (แกน Z โลก)
            temp_zaxis = xaxis.cross(yaxis)
            
            # หาก temp_zaxis เป็นศูนย์ แสดงว่า xaxis และ yaxis ขนานกัน
            # ซึ่งเป็นไปได้ถ้า xaxis อยู่ในระนาบ XY และ yaxis เป็น Z_AXIS
            # ในกรณีนี้ เราต้องหา zaxis ที่ตั้งฉากกับ xaxis และอยู่ในระนาบ XY
            # หรือกำหนด yaxis เป็นทิศทางที่ตั้งฉากกับ xaxis และ zaxis
            if temp_zaxis.length < 0.001.mm
                UI.messagebox("Internal error: Z-axis calculation resulted in zero length for non-vertical line. This can happen if the line lies perfectly on the world XY plane and Y-axis is defined as Z-axis.")
                
                # ถ้าเส้นนำทางอยู่ในระนาบ XY และ Y-axis คือ Z-axis,
                # ให้ลองใช้ Model X หรือ Y axis เป็น Y-axis แทน
                if xaxis.parallel?(model_xaxis)
                    # ถ้าเส้นนำทางขนานกับแกน X ของโลก ให้ Y เป็นแกน Y โลก
                    # (เพื่อสร้างระนาบ XY ที่ถูกต้องกับ Z-axis ที่ใช้เป็นความหนา)
                    yaxis = model_yaxis.normalize
                elsif xaxis.parallel?(model_yaxis)
                    # ถ้าเส้นนำทางขนานกับแกน Y ของโลก ให้ Y เป็นแกน X โลก
                    yaxis = model_xaxis.normalize
                else
                    # ถ้าเส้นนำทางอยู่ในระนาบ XY แต่ไม่ขนานกับแกน X หรือ Y ของโลก
                    # ให้ Z-axis เป็น Model Z-axis และ Y-axis ตั้งฉากกับ X-axis ในระนาบ XY
                    # ลองหาเวกเตอร์ที่ตั้งฉากกับ xaxis และอยู่ในระนาบ XY
                    # ซึ่งก็คือ cross product ของ xaxis กับ model_zaxis (เดิม)
                    # แต่ถ้าเดิมเป็นศูนย์ อาจต้องหมุน xaxis 90 องศาในระนาบ XY
                    
                    # วิธีที่ปลอดภัยกว่าคือการสร้าง Y-axis ให้ตั้งฉากกับ X-axis และชี้ขึ้นตาม Z โลก
                    # และ Z-axis ตั้งฉากกับ X-axis และ Y-axis
                    # แต่ถ้า X-axis อยู่ในระนาบ XY และ Y-axis เป็น Z-axis แล้ว cross product เป็น 0
                    # แสดงว่า X-axis เป็นตัวแทนของเวกเตอร์ในระนาบ XY
                    # เราสามารถเลือกให้ Y-axis เป็น Z-axis ของโลกได้ และ Z-axis เป็น cross(X, Y)
                    # ซึ่งเราทำไปแล้ว แต่ถ้าผลเป็น 0 ก็ต้องหาวิธีอื่น
                    
                    # ลองเปลี่ยนวิธีการกำหนด Y-axis: ให้ Y-axis เป็นเวกเตอร์ที่ตั้งฉากกับ X-axis และอยู่ในระนาบ XY (Z=0)
                    # และ Z-axis เป็น Model Z-axis (เพื่อความหนา)
                    
                    # สร้างเวกเตอร์ที่ตั้งฉากกับ xaxis ในระนาบ XY
                    # โดยการหมุน xaxis 90 องศาในระนาบ XY
                    # หาก xaxis = (x,y,0)  yaxis_candidate = (-y,x,0)
                    yaxis_candidate = Geom::Vector3d.new(-xaxis.y, xaxis.x, 0)
                    if yaxis_candidate.length < 0.001.mm # ถ้า xaxis เป็น (0,0,0) ซึ่งถูกดักไปแล้ว
                        UI.messagebox("Critical error: Cannot determine orthogonal Y-axis for non-vertical line.")
                        raise "Critical error: Cannot determine orthogonal Y-axis for non-vertical line."
                    end
                    yaxis = yaxis_candidate.normalize
                    zaxis = model_zaxis.normalize # ความหนาจะไปตามแกน Z ของโลก
                    
                    puts "Debug: Adjusted yaxis to #{yaxis.inspect} (planar) and zaxis to #{zaxis.inspect} (model Z) due to collinearity."
                end
            else
                zaxis = temp_zaxis.normalize
            end
          end

          # ตรวจสอบขั้นสุดท้ายว่า yaxis และ zaxis มีค่าและมีความยาวที่ถูกต้อง
          unless yaxis && yaxis.length > 0.001.mm && zaxis && zaxis.length > 0.001.mm
            UI.messagebox("Error: Final Y or Z axis is invalid after calculation.")
            puts "Debug: Final yaxis length: #{yaxis&.length}, Final zaxis length: #{zaxis&.length}"
            raise "Invalid final axes after calculation"
          end

          # Debug: พิมพ์ค่าแกนสุดท้ายที่จะใช้ในการสร้าง Transformation
          puts "Debug: Final xaxis (length direction) = #{xaxis.inspect}"
          puts "Debug: Final yaxis (height direction) = #{yaxis.inspect}"
          puts "Debug: Final zaxis (depth direction) = #{zaxis.inspect}"

          # Debug: พิมพ์ค่าจุดเริ่มต้นของ Transformation
          puts "Debug: Guide line start point for transform: #{@guide_line_start_pt.inspect}"

          # สร้าง Transformation โดยใช้ Geom::Transformation.axes
          # Origin: guide_line_start_pt
          # X-axis: xaxis (ทิศทางตามเส้นนำทาง)
          # Y-axis: yaxis (ทิศทางความสูงของกำแพง)
          # Z-axis: zaxis (ทิศทางความหนาของกำแพง)
          transform = Geom::Transformation.axes(@guide_line_start_pt, xaxis, yaxis, zaxis)
          puts "Debug: Transformation created: #{transform.inspect}"

          # สร้างจุดของสี่เหลี่ยมใน Local Coordinate System
          # จุดเริ่มต้น (0,0,0) ของสี่เหลี่ยมจะอยู่ที่ guide_line_start_pt
          # ด้านยาว (line_length) จะไปตาม xaxis
          # ด้านสูง (@rectangle_height) จะไปตาม yaxis
          # ความลึก (@rectangle_depth) จะใช้ในการ pushpull ตาม zaxis
          points_local = [
            Geom::Point3d.new(0, 0, 0),
            Geom::Point3d.new(line_length, 0, 0), # จุดสิ้นสุดตามความยาวของเส้นนำทาง
            Geom::Point3d.new(line_length, @rectangle_height, 0), # จุดสิ้นสุดตามความยาวและความสูง
            Geom::Point3d.new(0, @rectangle_height, 0) # จุดสิ้นสุดตามความสูง
          ]
          puts "Debug: points_local: #{points_local.inspect}"


          # แปลงจุดจาก Local Coordinate System ไปยัง Global Coordinate System
          points_global = points_local.map { |pt| pt.transform(transform) }
          
          # Debug: พิมพ์ค่า points_global ก่อน add_face
          puts "Debug: points_global for face creation: #{points_global.inspect}"

          # ตรวจสอบ points_global ก่อนสร้าง face
          unless points_global.is_a?(Array) && points_global.length == 4 && points_global.all? { |pt| pt.is_a?(Geom::Point3d) }
              UI.messagebox("Error: Invalid points generated for face creation.")
              raise "Invalid points for face creation"
          end
            
          # Filter out near-duplicate points to prevent issues with add_face
          # เพิ่ม tolerance เพื่อแก้ปัญหาจุดที่ใกล้กันมาก ๆ
          unique_points = []
          points_global.each do |pt|
              unless unique_points.any? { |p| p.distance(pt) < 0.0001.mm } # ใช้ tolerance ที่เหมาะสม (0.0001 มม.)
                  unique_points << pt
              end
          end

          if unique_points.length < 3
              UI.messagebox("Error: Not enough unique points to create a face. Points might be too close or collinear.")
              puts "Unique points for face creation: #{unique_points.inspect}"
              raise "Not enough unique points"
          end

          # สร้าง Face
          face = entities.add_face(points_global)

          if face && face.valid?
            # ตรวจสอบ Normal ของ Face และปรับให้หันไปในทิศทางเดียวกับ zaxis ที่คำนวณมา
            # ถ้า zaxis คือทิศทางความหนา Face Normal ควรชี้ไปในทิศทางนั้น
            if face.normal.dot(zaxis) < 0 
              face.reverse!
            end

            # ดัน Face ขึ้น/ลง ตามค่า @rectangle_depth
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
          # คอมมิต Operation เสมอ ไม่ว่าจะเกิดข้อผิดพลาดหรือไม่
          model.commit_operation
        end

        # รีเซ็ตเครื่องมือเพื่อรอการสร้างสี่เหลี่ยมถัดไป
        @state = 0
        @first_input_point.clear
        @second_input_point.clear
        @guide_line_start_pt = nil
        @guide_line_end_pt = nil
        update_ui
      end
      view.invalidate
    end

    # เมธอด onMouseMove จะถูกเรียกเมื่อเมาส์เคลื่อนที่
    def onMouseMove(flags, x, y, view)
      if @state == 0
        @first_input_point.pick(view, x, y)
        view.tooltip = @first_input_point.tooltip if @first_input_point.valid?
      elsif @state == 1
        # กำลังวาดเส้นนำทาง: อัปเดตจุดปัจจุบัน
        @second_input_point.pick(view, x, y, @first_input_point)
        @guide_line_end_pt = @second_input_point.position if @second_input_point.valid?
        
        # อัปเดตความยาวของเส้นนำทางใน tooltip
        current_length = @guide_line_start_pt && @guide_line_end_pt ? @guide_line_start_pt.distance(@guide_line_end_pt) : 0
        view.tooltip = "Length: #{Sketchup.format_length(current_length)}"
      end
      view.invalidate # บังคับให้ View วาดใหม่เพื่อแสดงตัวอย่าง
      update_ui
    end

    # เมธอด draw จะถูกเรียกทุกครั้งที่ View ถูก Refresh เพื่อวาดสิ่งต่างๆ
    def draw(view)
      @first_input_point.draw(view) if @first_input_point && @first_input_point.valid?

      # วาดเส้นนำทางขณะลาก
      if @state == 1 && @guide_line_start_pt && @guide_line_end_pt
        view.drawing_color = 'red' # เส้นนำทางสีแดง
        view.line_width = 3
        view.draw_lines(@guide_line_start_pt, @guide_line_end_pt)
      end
    end

    # เมธอด onSetCursor จะถูกเรียกเมื่อ SketchUp ต้องการตั้งค่า Cursor
    def onSetCursor
      UI.set_cursor(632) # รหัสสำหรับ cursor ดินสอใน SketchUp
      true # คืนค่า true เพื่อบอกว่าเราได้ตั้งค่า cursor แล้ว
    end

    # เมธอด onCancel จะถูกเรียกเมื่อผู้ใช้กด ESC
    def onCancel(reason, view)
      @state = 0
      @first_input_point.clear if @first_input_point
      @second_input_point.clear if @second_input_point
      @guide_line_start_pt = nil
      @guide_line_end_pt = nil
      view.invalidate
      update_ui
      # เมื่อกด ESC ในโหมดวาดเส้น ให้กลับไปป้อนขนาด
      prompt_for_dimensions if reason == 0 # Reason 0 คือปกติ (ไม่ใช่เปลี่ยนเครื่องมือ)
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
          current_length = @guide_line_start_pt && @guide_line_end_pt ? @guide_line_start_pt.distance(@guide_line_end_pt) : 0
          Sketchup.status_text = "Click to set the second point of the guide line. Current Length: #{Sketchup.format_length(current_length)}"
        end
      end
    end

    # เมธอดสำหรับแสดง InputBox เพื่อรับขนาด (ตอนนี้เหลือแค่ Height และ Depth)
    @@last_entered_height = nil
    @@last_entered_depth = nil

    def prompt_for_dimensions
      @@last_entered_height ||= 2500.mm # ค่าเริ่มต้นสำหรับความสูงกำแพง
      @@last_entered_depth ||= 100.mm  # ค่าเริ่มต้นสำหรับความหนากำแพง

      height_display = Sketchup.format_length(@@last_entered_height)
      depth_display = Sketchup.format_length(@@last_entered_depth)

      prompts = ["Height (Vertical):", "Depth (Thickness):"]
      defaults = [height_display, depth_display]
      results = UI.inputbox(prompts, defaults, "Enter Wall Dimensions")

      if results # ถ้าผู้ใช้กด OK
        temp_height = Sketchup.parse_length(results[0])
        temp_depth = Sketchup.parse_length(results[1])

        # ตรวจสอบค่าที่ได้จากการแปลงอย่างรอบคอบ
        if temp_height && temp_height > 0 && temp_depth && temp_depth > 0
          @rectangle_height = temp_height
          @rectangle_depth = temp_depth

          @@last_entered_height = @rectangle_height
          @@last_entered_depth = @rectangle_depth

          Sketchup.status_text = "Click to set the first point of the guide line for a wall with Height: #{Sketchup.format_length(@rectangle_height)}, Depth: #{Sketchup.format_length(@rectangle_depth)}."
        else
          UI.messagebox("Height and Depth must be positive numeric values. Please try again.")
          # ยกเลิกเครื่องมือถ้าป้อนค่าไม่ถูกต้อง
          Sketchup.active_model.tools.pop_tool
          Sketchup.status_text = ""
        end
      else # ถ้าผู้ใช้กด Cancel
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
    # ตรวจสอบให้แน่ใจว่าไฟล์รูปภาพอยู่ในโฟลเดอร์ 'images' ภายในโฟลเดอร์ปลั๊กอินของคุณ
    cmd.small_icon = File.join(__dir__, "images", "wall_tool_small.png") 
    cmd.large_icon = File.join(__dir__, "images", "wall_tool_large.png") 
    toolbar.add_item(cmd)
    toolbar.show

    file_loaded(__FILE__)
  end

end # module MyAwesomeTool