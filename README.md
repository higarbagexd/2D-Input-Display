# 2D-Input-Display
2D Input Display for both controllers and keyboards.









## Known Issues
1. I used my 8BitDo Ultimate 2 Controller for the testing of this application. When the controller is on the '2.4GHz", Windows will recognize it as an 8BitDo Ultimate 2 Controller.
   However, when using the 'Blutooth" mode on this controller, Windows will recognize it as a Nintendo Switch Pro Controller. The issue is, if the controller is disconnected during app runtime,
   it will not register any inputs upon reconnection. I am not aware what causes this considering that SDL DOES detect that the controller is reconnected. I believe that this is most probably a
   fault for Windows, considering that it does not handle Nintendo Switch Controllers very well.
   
