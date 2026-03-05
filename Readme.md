# Frame

  Draws a cat-like frame using given parameters.
  

## Launch

  There are five parameters: length, width, size of ears, ASCII of the symbol that makes up the frame
and the text you want to see inside it. You should write them in that exact order in command line after the file with the programm. The length,
the width and the symbol are set with two numbers(from 00 to 99) and the ear size with only one(from 0 to 9).
```
cat.com 19 12 4 03 hello world
```

## Example

There's the picture you'll get using the parameters specified above.


<img width="1074" height="802" alt="image" src="https://github.com/user-attachments/assets/9415459e-ecf2-44a9-966f-882dedf10ce3" />


# Resident

  A resident programm which draws a frame with constanly updating register values inside if you press 'W'. You can stop the values
  update by pressing 'E' and close the frame with 'Q'.

## Launch

  There's no parameters for launching:

  ```
resident.com
```
  The programm will change the int 09h and int 08h addresses to its own functions' ones. Now you can try pressing 'W', 'Q' or 'E'.

## Example

<img width="986" height="963" alt="image" src="https://github.com/user-attachments/assets/2fcb77af-fd8c-4472-8ad4-53a0861308af" />





