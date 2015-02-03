function varargout = controller(varargin)
% CONTROLLER MATLAB code for controller.fig
%      CONTROLLER, by itself, creates a new CONTROLLER or raises the existing
%      singleton*.
%
%      H = CONTROLLER returns the handle to a new CONTROLLER or the handle to
%      the existing singleton*.
%
%      CONTROLLER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTROLLER.M with the given input arguments.
%
%      CONTROLLER('Property','Value',...) creates a new CONTROLLER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before controller_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to controller_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help controller

% Last Modified by GUIDE v2.5 20-Aug-2012 16:24:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @controller_OpeningFcn, ...
                   'gui_OutputFcn',  @controller_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before controller is made visible.
function controller_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to controller (see VARARGIN)

% Choose default command line output for controller
handles.output = hObject;

clc

% % % % % % % % Transaction packet framing
% % % % % % % % ====================================================
% % % % % % % % | SyncOne | SynTwo | Command | Argument | Checksum |
% % % % % % % % ====================================================

handles.SyncOne         = 85;  %0x55
handles.SyncTwo         = 170; %0xAA

handles.CMDConnection   = 20;
handles.CMDMove         = 21;

handles.ArgSync         = 30;
handles.ArgAck          = 31;
handles.ArgNack         = 32;
handles.ArgFin          = 33;

handles.ArgLeft         = 40;
handles.ArgRight        = 41;
handles.ArgUp           = 42;
handles.ArgDown         = 43;
handles.ArgForward      = 44;
handles.ArgBackward     = 45;
handles.ArgStop         = 46;
handles.ArgCalHigh      = 47;
handles.ArgCalLow       = 48;


handles.CurrentSpace = {0 , 0 ,  0};
handles.RefSpace     = {0 , 0 ,  0};

handles.PortAvailable = false; 
handles.PortConnected = false;
handles.MovementAuto  = false;
handles.CameraExist   = false;
handles.CameraStart   = false;

%Disable Movement Section
set(handles.PB_LEFT       ,'Enable','off');
set(handles.PB_RIGHT      ,'Enable','off');
set(handles.PB_UP         ,'Enable','off');
set(handles.PB_DOWN       ,'Enable','off');
set(handles.PB_FORWARD    ,'Enable','off');
set(handles.PB_BACKWARD   ,'Enable','off');
set(handles.PB_STOP       ,'Enable','off');
set(handles.PB_AUTOMANUAL ,'Enable','off');

set(handles.PB_CAPTURE ,'Enable','off');


handles.hSerial = serial('COM1');
set(handles.hSerial,'DataBits',8);
set(handles.hSerial,'StopBits',1);
set(handles.hSerial,'Parity','none');

handles.CapTimer = timer('Name','Capture');
set(handles.CapTimer,'ExecutionMode','fixedDelay');
set(handles.CapTimer,'Period',0.05);
set(handles.CapTimer,'StartDelay',3);



try
    handles.vid = RWGs();
    handles.CameraExist = true;
catch
    handles.CameraExist = false;
    set(handles.ST_STATUS,'String','No Camera Detected!');
end

axes(handles.AX_CAMERA1);
t = title('Camera 1');
set(t,'FontWeight','Bold');
axes(handles.AX_CAMERA2);
t = title('Camera 2');
set(t,'FontWeight','Bold');
    


set(handles.CapTimer,'TimerFcn',{'Capture' , hObject , handles});



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes controller wait for user response (see UIRESUME)
% uiwait(handles.CONTROLPANEL);

% --- Outputs from this function are returned to the command line.
function varargout = controller_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


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
%==========================================================================
%==========================================================================
%GUI Function==============================================================
%==========================================================================
%==========================================================================
% --- Executes during object deletion, before destroying properties.
function CONTROLPANEL_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to CONTROLPANEL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    stop(handles.CapTimer);
end


if(handles.CameraExist == true)
    try
        stop(handles.vid);
        flushdata(handles.vid);
        delete(handles.vid);
    end
end


PortStatus = get(handles.hSerial,'Status');
    
if(strcmp(PortStatus,'open'))
    
    try
        fclose(handles.hSerial);
    end
    
end

delete(handles.hSerial);
delete(handles.CapTimer);

try
    close(handles.CamView);
end


% --- Executes on button press in PB_PORTCONNECT.
function PB_PORTCONNECT_Callback(hObject, eventdata, handles)
% hObject    handle to PB_PORTCONNECT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(strcmp( get( hObject , 'String' ) , 'Connect' ))
    
    PortNameList  = get(handles.PUM_PORTNAME,'string');
    PortNameIndex = get(handles.PUM_PORTNAME,'Value');
    PortName      = char(PortNameList(PortNameIndex));

    PortBaudList  = get(handles.PUM_PORTBAUD,'string');
    PortBaudIndex = get(handles.PUM_PORTBAUD,'Value');
    PortBaud      = char(PortBaudList(PortBaudIndex));


    set(handles.hSerial,'Port',PortName);
    set(handles.hSerial,'BaudRate',str2num(PortBaud));
    

    set(hObject,'Enable','off');
    set(handles.PUM_PORTNAME,'Enable','off');
    set(handles.PUM_PORTBAUD,'Enable','off');

    guidata(hObject, handles);

    PortStatus = get(handles.hSerial,'Status');

    if(strcmp(PortStatus,'closed'))

        try
            fopen(handles.hSerial);
            handles.PortAvailable = true;
        catch
            st = sprintf('No Device on Serial Port %s',PortName);
            set(handles.ST_STATUS,'String',st);
            set(hObject,'Enable','on');
            set(handles.PUM_PORTNAME,'Enable','on');
            set(handles.PUM_PORTBAUD,'Enable','on');
            handles.PortAvailable = false;
            return;
        end
    end

    if(handles.PortAvailable)
        set(handles.ST_STATUS,'String','Connecting to Device...');
        pause(1);
        
        if(SendCommand(handles,handles.CMDConnection,handles.ArgSync))
            set(handles.ST_STATUS,'String','Device Connected');
            handles.PortConnected = true;
            set(hObject,'String','Disconnect');
            set(hObject,'Enable','on');
            
            %Enable Movement section
            set(handles.PB_LEFT       ,'Enable','on');
            set(handles.PB_RIGHT      ,'Enable','on');
            set(handles.PB_UP         ,'Enable','on');
            set(handles.PB_DOWN       ,'Enable','on');
            set(handles.PB_FORWARD    ,'Enable','on');
            set(handles.PB_BACKWARD   ,'Enable','on');
            set(handles.PB_STOP       ,'Enable','on');
            set(handles.PB_AUTOMANUAL ,'Enable','on');
            
            guidata(hObject, handles);
            return;
        
        else
   
            fclose(handles.hSerial);
            handles.PortConnected = false;
            handles.PortAvailable = false;
            set(handles.ST_STATUS,'String','Device Connection Failed!');
            set(hObject,'Enable','on');
            set(handles.PUM_PORTNAME,'Enable','on');
            set(handles.PUM_PORTBAUD,'Enable','on');
                        
            guidata(hObject, handles);
        end       
        
    end

else
    
    fclose(handles.hSerial);
    handles.PortConnected = false;
    handles.PortAvailable = false;
    handles.MovementAuto  = false;
    set(handles.CapTimer,'TimerFcn',{'Capture' , hObject , handles});
    set(handles.ST_STATUS,'String','Device Disconnected');
    set(hObject,'String','Connect');
    set(hObject,'Enable','on');
    set(handles.PUM_PORTNAME,'Enable','on');
    set(handles.PUM_PORTBAUD,'Enable','on');
    
    %Disable Movement Section
    set(handles.PB_LEFT,'Enable','off');
    set(handles.PB_RIGHT,'Enable','off');
    set(handles.PB_UP,'Enable','off');
    set(handles.PB_DOWN,'Enable','off');
    set(handles.PB_FORWARD,'Enable','off');
    set(handles.PB_BACKWARD,'Enable','off');
    set(handles.PB_STOP,'Enable','off');
    set(handles.PB_AUTOMANUAL,'Enable','off');

    guidata(hObject, handles);
end
  


% --- Executes on button press in PB_RIGHT.
function PB_RIGHT_Callback(hObject, eventdata, handles)
% hObject    handle to PB_RIGHT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgRight);


% --- Executes on button press in PB_LEFT.
function PB_LEFT_Callback(hObject, eventdata, handles)
% hObject    handle to PB_LEFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgLeft);


% --- Executes on button press in PB_UP.
function PB_UP_Callback(hObject, eventdata, handles)
% hObject    handle to PB_UP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgUp);

% --- Executes on button press in PB_DOWN.
function PB_DOWN_Callback(hObject, eventdata, handles)
% hObject    handle to PB_DOWN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgDown);


% --- Executes on button press in PB_FORWARD.
function PB_FORWARD_Callback(hObject, eventdata, handles)
% hObject    handle to PB_FORWARD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgForward);


% --- Executes on button press in PB_BACKWARD.
function PB_BACKWARD_Callback(hObject, eventdata, handles)
% hObject    handle to PB_BACKWARD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);
pause(0.1);
SendCommand(handles,handles.CMDMove,handles.ArgBackward);



% --- Executes on button press in PB_STOP.
function PB_STOP_Callback(hObject, eventdata, handles)
% hObject    handle to PB_STOP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgStop);


% --- Executes on button press in PB_AUTOMANUAL.
function PB_AUTOMANUAL_Callback(hObject, eventdata, handles)
% hObject    handle to PB_AUTOMANUAL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ( strcmp( get( hObject , 'String' ) , 'Automatic' ) )
    handles.MovementAuto = true;
    set( hObject , 'String' , 'Manual' );
    set(handles.ST_STATUS,'String','Automatic Control');
    
    set(handles.PB_LEFT,'Enable','off');
    set(handles.PB_RIGHT,'Enable','off');
    set(handles.PB_UP,'Enable','off');
    set(handles.PB_DOWN,'Enable','off');
    set(handles.PB_FORWARD,'Enable','off');
    set(handles.PB_BACKWARD,'Enable','off');
    set(handles.PB_STOP,'Enable','off');
    
else
    handles.MovementAuto = false;
    set( hObject , 'String' , 'Automatic' );
    set(handles.ST_STATUS,'String','Manual Control');
    
    set(handles.PB_LEFT,'Enable','on');
    set(handles.PB_RIGHT,'Enable','on');
    set(handles.PB_UP,'Enable','on');
    set(handles.PB_DOWN,'Enable','on');
    set(handles.PB_FORWARD,'Enable','on');
    set(handles.PB_BACKWARD,'Enable','on');
    set(handles.PB_STOP,'Enable','on');
end


set(handles.CapTimer,'TimerFcn',{'Capture' , hObject , handles});

guidata(hObject, handles);


% --- Executes on button press in PB_CAMSTART.
function PB_CAMSTART_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CAMSTART (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.CameraExist == true)
    
    if ( strcmp( get( hObject , 'String' ) , 'Start' ) )
        
        
        try
            start(handles.CapTimer);
            start(handles.vid);
            
            handles.CameraStart   = true;
            set( hObject , 'String' , 'Stop' );
            set(handles.CapTimer,'TimerFcn',{'Capture' , hObject , handles});
            set(handles.ST_STATUS,'String','Camera Started');
            set(PB_CAPTURE,'Enable','off');
        catch
            set(handles.ST_STATUS,'String','Camera Failed to Start');
        end
        

    else
        handles.CameraStart   = false;
        set( hObject , 'String' , 'Start' );

        try
            stop(handles.CapTimer);
            stop(handles.vid);
            set(handles.ST_STATUS,'String','Camera Stoped');
            set( hObject , 'String' , 'Stop' );
            set(PB_CAPTURE,'Enable','on');
        catch
            set(handles.ST_STATUS,'String','Camera Failed to Stop');
        end

    end
    
else
    
    try
        handles.vid = RWGs();
        handles.CameraExist = true;
    catch
        handles.CameraExist = false;
        set(handles.ST_STATUS,'String','No Camera Detected!');
    end
    
end


 guidata(hObject, handles);

% --- Executes on button press in PB_CAPTURE.
function PB_CAPTURE_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CAPTURE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.RefSpace = handles.CurrentSpace;
guidata(hObject, handles);

set(handles.ST_STATUS,'String','Refrence Saved!');
set(handles.CapTimer,'TimerFcn',{'Capture' , hObject , handles});

set(hObject,'Enable','off');


% --- Executes on button press in PB_EXIT.
function PB_EXIT_Callback(hObject, eventdata, handles)
% hObject    handle to PB_EXIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

quit();


% --- Executes on button press in PB_CALENABLE.
function PB_CALENABLE_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALENABLE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in PB_CALS1.
function PB_CALS1_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALS1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgLeft);
SendCommand(handles,handles.CMDMove,handles.ArgForward);


% --- Executes on button press in PB_CALS2.
function PB_CALS2_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALS2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgRight);
SendCommand(handles,handles.CMDMove,handles.ArgBackward);


% --- Executes on button press in PB_CALS3.
function PB_CALS3_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALS3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgUp);


% --- Executes on button press in PB_CALS4.
function PB_CALS4_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALS4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgDown);


% --- Executes on button press in PB_CALSET.
function PB_CALSET_Callback(hObject, eventdata, handles)
% hObject    handle to PB_CALSET (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SendCommand(handles,handles.CMDMove,handles.ArgCalLow);
pause(1);
SendCommand(handles,handles.CMDMove,handles.ArgCalHigh);
