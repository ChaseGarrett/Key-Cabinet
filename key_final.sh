#Progarm by Chase Cummins, Cody Bennett, and Jeff Bostian

#Wednesday May 1st, 2019 at 3:37 pm



#Variable Initialization and Declaration

cardID=0

keyID=0

user_allow=0

user_scan=0

key_scan=0

key_allow=0

fail_scan=0

fail_allow=0

key_in=0

name=0

door_closed=1


#Setting the modes for the GPIO pins used throughout the program

gpio -g mode 16 IN

gpio -g mode 21 OUT

gpio -g mode 13 OUT

gpio -g mode 19 OUT

gpio -g write 13 0

gpio -g write 19 0

gpio -g write 21 0


#Enter a while loop that always runs, because our code needs to run constantly.

while [ 1 ]; do

   #echo "waiting on user id"

   #If a card is scanned, the scanned value is recorded in the variable "cardID."
   #We ssh into the authentication pi, entering the user file, and searching for the cardID we just gathered.
   #If we find a cooresponding entry, we set user_scan to the value returned.

   read cardID

   user_scan=$(ssh pi@152.41.14.225 -p 2512 "cat /home/pi/final_proj/user.database | grep ${cardID}")

   user_allow=$(echo $?)


   #If the "cardID" was found on the authentication pi, no error is returned and the user is allowed to access the key cabinet.
   #Upon entering the loop, we ssh into the authentication pi and log the date and time the user scanned in along with the username,
   #from the user.database. 

   if [ ${user_allow} -eq 0 ]; then

      ssh pi@152.41.14.225 -p 2512 "echo $(date +%Y-%m-%d_%T) ${user_scan} IN >>/home/pi/final_proj/user.log"

      name=$(echo ${user_scan} | awk '{ print $2 }')


      #We disable the maglock by providing power to GPIO pin 21 then, when the cabinet springs open, turn the maglock on again.
      #We then determine whether the door is closed or not, since reading GPIO pin 16 will return a 1 if the door is closed.
      #Lastly, we enter a while loop that runs as long as the door is open.

      gpio -g write 21 1

      sleep 1

      door_closed=$(gpio -g read 16)

      gpio -g write 21 0

      while [ ${door_closed} -eq 0 ]; do

         #echo "\nName before key: ${name}"

         #We turn on the green led, telling the user that they can scan the next key, and wait 10 seconds for a key to be scanned.
         #If a key is scanned, we write the value to "keyID" and switch the green led to a red one, since a new key cannot be read currently.

         gpio -g write 19 0

         gpio -g write 13 1

         keyID=$(bash -c 'read -t 10 X;echo $X')

         gpio -g write 13 0

         gpio -g write 19 1


         #We scan the length of the newly scanned value, since our keyID's were all 10 characters in length.
	 #If the user accidentally scanned their either their ID or a card that wasn't 10 characters long, do nothing.
	 #If it was 10 characters long, however, check key.database for the key and whether it is currently checked in or out.

         keylength=$(echo ${keyID}|awk '{print length($1)}')

         #echo "The keyID is: ${keyID}"

	 #echo "The key has a length of ${keylength}"

         if [ ${keylength} -eq 10 ]; then

            key_scan=$(ssh pi@152.41.14.225 -p 2512 "cat /home/pi/final_proj/key.database | grep ${keyID}")

            key_allow=$(echo $?)


	    #If the key matches a key found in key.database and no error is produced, proceed with the code.
	    #Record whether the key is checked in and the name of the key, i.e. where the key is used for IT.

            if [ ${key_allow} -eq 0 ]; then

               key_in=$(echo ${key_scan} | awk '{ print $2 }' )

               keyname=$(echo ${key_scan} | awk '{ print $3 }' )


	       #If the key is not in, log the time, date, keyname, and the user returning the key.
	       #Then search the key.log file and log the key as being returned via the "sed" function.

               if [ ${key_in} -eq 0 ]; then

                  ssh pi@152.41.14.225 -p 2512 "echo $(date +%Y-%m-%d_%T) \"${keyname} key was returned by ${name}\" >>/home/pi/final_proj/key.log"

                  ssh pi@152.41.14.225 -p 2512 "sed -i 's/${keyID}  0        ${keyname}/${keyID}  1        ${keyname}/' /home/pi/final_proj/key.database"


	       #If the key is in, log the time, date, keyname, and the user returning the key.
	       #Then, similarly to scanning the key in, log the key as being takin out in the key.log file.

               else

                  ssh pi@152.41.14.225 -p 2512 "echo $(date +%Y-%m-%d_%T) \"${keyname} key was taken out by ${name}\" >>/home/pi/final_proj/key.log"

                  ssh pi@152.41.14.225 -p 2512 "sed -i 's/${keyID}  1        ${keyname}/${keyID}  0        ${keyname}/' /home/pi/final_proj/key.database"

               fi

            fi

         fi

	
	 #Determine if the door is closed; if it is, log the date and time the current user closed the door. 
	 #If the door is still open, loop through the while loop with the door closed condition.

         door_closed=$(gpio -g read 16)

         #echo "Door closed: ${door_closed}"

         #read -p "Is the door closed? 1 for yes, 0 for no" door_closed

      done

      if [ ${door_closed} -eq 1 ]; then

         ssh pi@152.41.14.225 -p 2512 "echo $(date +%Y-%m-%d_%T) ${user_scan} OUT >>/home/pi/final_proj/user.log"

      fi

   fi

#If the user's card number is not found on the authentication pi, we check to make sure the failed scan isn't a key number in key.database.
#If the failed scan is a key number, do nothing. If it isn't, we know an unathenticated user is trying to gain access.
#Echo the date, time, and the card number that failed to scan in in our userfail.log. Since we don't have a list of all users within the
#school, we can't gather a name of the user associated with the cardID, so we just store it in userfail.log. 

#Any cardID within userfail.log can just be searched later by an administrator if need be.

if [ ${user_allow} -ne 0 ]; then

      fail_scan=$(ssh pi@152.41.14.225 -p 2512 "cat /home/pi/final_proj/key.database | grep ${cardID}")

      fail_allow=$(echo $?)

      if [ ${fail_allow} -ne 0 ]; then

         ssh pi@152.41.14.225 -p 2512 "echo $(date +%Y-%m%d_%T) \"Card ${cardID} failed to login.\" >>/home/pi/final_proj/userfail.log"

      fi

   fi


   #At the end of every pass, we clear the cardID, keyID, user_scan, key_scan, and name so that they may be used again at the 
   #beginning of the loop.

   #echo "\nDeleting variables..."

   cardID=0

   keyID=0

   user_scan=0

   key_scan=0

   name=0

done
