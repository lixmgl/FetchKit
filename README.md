1.Time: 
  I spend 4 hours to finish this assignment.

2.This Command line interface contain two classes:
  The first is FetchKit, which can fetch id and link for each kit.
  It can also fetch detail information in each kit.
  According to API:
  https://typekit.com/docs/api/v1/:format/kits
  https://typekit.com/docs/api/v1/:format/kits/:kit

3.Token:
  I registered an Adobe ID to generate my API Token, which is:
  a946de0ea6cf7147233d783c2c520dab254c15e2

  This token can only generate one kit for me since it is free.

4.Input the command with token in terminal to run the code:
  $ruby fetchKit --token=a946de0ea6cf7147233d783c2c520dab254c15e2 

5.User can get id and link for each kit
  After that, user can input 'p' to print all details of the kit.
  Or input 'q' to exit early.
  Or input number for the kit they want to see details.
  If they input a wrong number which larger than total kits number, it will show error message.

6.Reference:
    https://github.com/typekit/typekit-api-examples/tree/master/kitgen
    Used this API to create kit for my token before I fetch data.

7.test_CLI.rb is unit test for this program
  $ruby test_CLI.rb
  It can test if you can fetch the same kit id which you created.
  
  
