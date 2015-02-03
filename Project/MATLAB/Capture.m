function Capture(varargin)
%CAPTURE Summary of this function goes here
%   Detailed explanation goes here

hObject = varargin{3};
handles = varargin{4};

PointExist = true;


if((handles.vid(1).FramesAcquired >= 200) || (handles.vid(2).FramesAcquired >= 200))   %if the number of frames raeched 2000, flush data
        flushdata(handles.vid);
end
    
    
    
    data1 = getdata(handles.vid(1),1);   %trig and get the frame from the camera
    data2 = getdata(handles.vid(2),1);   %trig and get the frame from the camera
    
    
    gray = rgb2gray(data1);  %converts the truecolor image RGB to the grayscale intensity image
    red  = data1(:,:,1);
    diff_im1 = imsubtract(red, gray);    %removing the luminance of the r & g and b remains unchanged
    
    gray = rgb2gray(data2);  %converts the truecolor image RGB to the grayscale intensity image
    red  = data2(:,:,1);
    diff_im2 = imsubtract(red, gray);    %removing the luminance of the r & g and b remains unchanged
    
    
    diff_im1 = medfilt2(diff_im1, [2 2]);  %moving average filter
    diff_im2 = medfilt2(diff_im2, [2 2]);  %moving average filter

    diff_im1 = im2bw(diff_im1,0.2);    %Threshold for the bw intensity (between 1-0)
    diff_im2 = im2bw(diff_im2,0.2);    %Threshold for the bw intensity (between 1-0)
   
   
    
    % Remove all those pixels less than 300px
    diff_im1 = bwareaopen(diff_im1,800);
    diff_im2 = bwareaopen(diff_im2,800);
    
    
    
    % Label all the connected components in the image.
    bw1 = bwlabel(diff_im1, 8);
    bw2 = bwlabel(diff_im2, 8);
    
    % Here we do the image block analysis.
    % We get a set of properties for each labeled region.
    stats1 = regionprops(bw1, 'BoundingBox', 'Centroid'); %the number of stats is equal to labels
    stats2 = regionprops(bw2, 'BoundingBox', 'Centroid'); %the number of stats is equal to labels
    
    try
        temp = get(handles.AX_CAMERA1);
    catch
        return;
    end
    
    axes(handles.AX_CAMERA1);
    imshow(data1);
    t = title('Camera1');
    set(t,'FontWeight','Bold');
    
    
    hold on
    %This loop bounds the blue objects in a rectangular box.
    if(length(stats1) == 1)
        bb = stats1(1).BoundingBox;
        bc = stats1(1).Centroid;
        rectangle('Position',bb,'EdgeColor','r','LineWidth',2)   %drawing a rectangular 
        plot(bc(1),bc(2), '-m+')   %printing '+'
        a=text(bc(1)+15,bc(2), strcat('Y: ', num2str(round(bc(1))), '    X: ', num2str(round(bc(2)))));
        set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
        
        handles.CurrentSpace{1} = round(bc(2));
        handles.CurrentSpace{2} = round(bc(1));
        
        if ( strcmp( get( handles.ST_STATUS , 'String' ) , 'Too Many Points on Camera!' ) )
            set(handles.ST_STATUS,'String','Ready');
        end
    
    elseif(length(stats1) > 1)
        set(handles.ST_STATUS,'String','Too Many Points on Camera!');
        PointExist = false;
    else
        set(handles.ST_STATUS,'String','No Point on Camera!');
        PointExist = false;
    end
    
    hold off  
    
    try
        temp = get(handles.AX_CAMERA2);
    catch
        return;
    end
    
    axes(handles.AX_CAMERA2);
    imshow(data2);
    t = title('Camera2');
    set(t,'FontWeight','Bold');
    
    hold on
    %This loop bounds the blue objects in a rectangular box.
    if(length(stats2) == 1)
        bb = stats2(1).BoundingBox;
        bc = stats2(1).Centroid;
        rectangle('Position',bb,'EdgeColor','r','LineWidth',2)   %drawing a rectangular 
        plot(bc(1),bc(2), '-m+')   %printing
        %
        a=text(bc(1)+15,bc(2), strcat('Z: ', num2str(round(bc(2)))));
        set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
        
        handles.CurrentSpace{3} = round(bc(2));
        
        if ( strcmp( get( handles.ST_STATUS , 'String' ) , 'Too Many Points on Camera!' ) )
            set(handles.ST_STATUS,'String','Ready');
        end
    
    elseif(length(stats2) > 1)
        set(handles.ST_STATUS,'String','Too Many Points on Camera!');
        PointExist = false;
    else
        set(handles.ST_STATUS,'String','No Point on Camera!');
        PointExist = false;
    end
    
    hold off
   

    
    
    if((handles.MovementAuto == true) && (PointExist == true))
        
        SendCommand(handles,handles.CMDMove,handles.ArgLeft);
        
    end
    
    
    
disp(handles.RefSpace);

guidata(hObject, handles);

end

%User Function=============================================================
%==========================================================================
%==========================================================================
%==========================================================================
%==========================================================================
function Frame = FramePack(Command,Argument)

Frame = uint8(zeros(1,5));
Frame(1) = uint8(85);
Frame(2) = uint8(170);
Frame(3) = uint8(Command);
Frame(4) = uint8(Argument);

Frame(5) = bitxor(Frame(1),Frame(2));
Frame(5) = bitxor(Frame(5),Frame(3));
Frame(5) = bitxor(Frame(5),Frame(4));

if(Frame(5) == 0)
    Frame(5) = 255;
end

end
%==========================================================================
%==========================================================================
function [Command Argument] = FrameUnpack(Frame)

Command  = uint8(0);
Argument = uint8(0);

if(length(Frame) ~= 5)
    return;
end

if( (Frame(1) ~= uint8(85)) && (Frame(2) ~= uint8(170)) )
    return;
end

Checksum = bitxor(Frame(1),Frame(2));
Checksum = bitxor(Checksum,Frame(3));
Checksum = bitxor(Checksum,Frame(4));

if(Checksum == 0)
    Checksum = 255;
end

if(Checksum ~= Frame(5))
    return;
end

Command  = Frame(3);
Argument = Frame(4);

end
%==========================================================================
%==========================================================================
function Status = SendCommand(handles , Command , Argument)
        

        Status = false;
        set(handles.ST_STATUS,'String','Sending Command to Device...');
        i = 0;  
        while(i < 2)
            
            SendFrame = FramePack(Command,Argument);
            
            try
                fwrite(handles.hSerial,SendFrame);
            catch
                set(handles.ST_STATUS,'String','Command Failed!');
            end
            
            
            
            if(get(handles.hSerial,'BytesAvailable') >= 5)
                
                RecvFrame = uint8(fread(handles.hSerial,5));
                
                [RecvCommand RecvArgument] = FrameUnpack(RecvFrame);
                     
                
                if((RecvCommand == Command) && (RecvArgument == handles.ArgAck))                    
                    Status = true;
                    set(handles.ST_STATUS,'String','Command Done');
                    return;
                end
            end
            
            pause(i);
            i = i + 0.1;
        end

        set(handles.ST_STATUS,'String','Command Failed!');
end