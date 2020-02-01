#displays the menu using the suggested forground and background colors
displayTheMenu(){

	echo -e "\e[4m\e[1;31;43mROCKY Theatre's Self-service Ticketing\e[0m" 
	echo 
	echo -e "\e[1;34m1) List all Movies and Show times"
	echo "2) Fast booking (where system will automatically select best seat)"
	echo "3) To select theatre's seat manually"
	echo "4) Search by Show time or movie title"
	echo -e "5) Quit\e[0m" 

}

#lists movies screening, showtimes and availability based on the data read from the file ticketinglist.txt
listMovieInformation(){

echo
	echo -e "\e[4m\e[1;31;43mROCKY Theatre's Screening Movies\e[0m"
	echo
	#use of sed to prepare display as suggested (switching columns, replacing fields, eliminating delimiters/braces)
	cat <<EOF>sedscript
		s@\(.*\),\(.*\),\(.*\)@,\2,\1,\3@g
		s@ *,@,@g
		s/No/SOLD OUT/g
		s/Yes/Ticket Available/g
		s/\[//g
		s/\]//g
		: width
		s@,\([^,]\{0,18\}\),@,\1 ,@g
		t width
		s@^,@@g
		s/,//g
EOF
sed -f sedscript ticketlist.txt

}

#prints the optimally selected seats in the theatre. This function is internally invoked by the automaticallySelectBestSeat
#function with appropriate arguments
printTheTheatre(){

	#variable to store the first argument to the function (utilized to check if the requested number of seats is equal 
	#to or less than the available seats)
	value=$1
	
	counter=0
	seatRanker=0

	#if the number of seats requested is equal to those avaiable, all vacant seats are automatically selected for the user
	if test $value -eq 1
	then
		ticketsToBook=$2
		echo -e "\e[4m\e[1;33;45m        SCREEN          \e[0m"
		echo -n "    A   B   C   D   E"

		while [ $counter -lt 20 ]
		do
			if [[ $(($counter % 5)) -eq 0 ]]
			then
				echo 
				let "seatRanker=$seatRanker+1"
				echo -n "$seatRanker"
				
			fi
			
			val=${matrix[$(($counter/5)),$(($counter%5))]}
			if [ $val == "_" ]
			then
				echo -e -n "\e[1;34m   X\e[0m"
				matrix[$(($counter/5)),$(($counter%5))]="X"	
			else
				echo -e -n "\e[1;31m   X\e[0m"
			fi

			let "counter=$counter+1"			

		done
		echo 
	
	#if the number of requested seats is less than those available, the program implements the below algorithm to optimally
	#select the best seats. Centralized seats and those nearer to the screen are considered superior to corner seats or 
	#those farther away from the screen
	else
		
		ticketsBooked=0
		ticketsToBook=$2
		declare -A seatsAvailable
		seatCounter=0
		counter=0
		
		while [ $counter -lt 20 ]
		do		
			val=${matrix[$(($counter/5)),$(($counter%5))]}
			if [ $val == "_" ]
			then
				row=$(($(($counter/5))+1))
				columnNumber=$(($counter%5))

				case $columnNumber in

					0*) 
						column="A"
						;;
					1*) 
						column="B"
						;;
					2*) 
						column="C"
						;;
					3*) 
						column="D"
						;;
					4*) 
						column="E"
						;;
				esac

				seatsAvailable[$seatCounter]="$column$row"
				let "seatCounter=$seatCounter+1"
			fi

			let "counter=$counter+1"			

		done

		#array to store optimally booked seats
		declare -A seatsBooked
		seatsBookedCounter=0

		#array to hold theatre seats in decreasing order of priority
		prioritizedSeats=(
			"B1" "C1" "D1" "A1" "E1" 
			"B2" "C2" "D2" "A2" "E2"
			"B3" "C3" "D3" "A3" "E3"
			"B4" "C4" "D4" "A4" "E4"
			)

		#storing optimal seats in the array seatsBooked
		for seat in "${prioritizedSeats[@]}"
		do
			if [ $ticketsBooked -eq $ticketsToBook ]
				then
					break
			fi

			for i in "${seatsAvailable[@]}"
			do
				if [ $i == $seat ]
				then
					seatsBooked[$seatsBookedCounter]="$i"
					let "seatsBookedCounter=$seatsBookedCounter+1"
					let "ticketsBooked=$ticketsBooked+1"
					break
				fi
			done
		done

		#array to hold the numeric representation of optimally booked seats, for ease of processing
		declare -A numericSeatsBooked
		numericSeatsBookedCounter=0

		for i in "${seatsBooked[@]}"
		do
			value=0
			case $i in
			"A1"*)
				value=0
				;;
			"B1"*)
				value=1
				;;
			"C1"*)
				value=2
				;;
			"D1"*)
				value=3
				;;
			"E1"*)
				value=4
				;;
			"A2"*)
				value=5
				;;
			"B2"*)
				value=6
				;;
			"C2"*)
				value=7
				;;
			"D2"*)
				value=8
				;;
			"E2"*)
				value=9
				;;
			"A3"*)
				value=10
				;;
			"B3"*)
				value=11
				;;
			"C3"*)
				value=12
				;;
			"D3"*)
				value=13
				;;
			"E3"*)
				value=14
				;;
			"A4"*)
				value=15
				;;
			"B4"*)
				value=16
				;;
			"C4"*)
				value=17
				;;
			"D4"*)
				value=18
				;;
			"E4"*)
				value=19
				;;
			esac

			numericSeatsBooked[$numericSeatsBookedCounter]=$value
			let "numericSeatsBookedCounter=$numericSeatsBookedCounter+1"

		done

		#prints the theatre seats (booked, unbooked and optimally selected ones)
		echo
		echo -e "\e[4m\e[1;33;45m        SCREEN          \e[0m"
		echo -n "    A   B   C   D   E"

		counter=0

		while [ $counter -lt 20 ]
		do
			if [[ $(($counter % 5)) -eq 0 ]]
			then
				echo 
				let "seatRanker=$seatRanker+1"
				echo -n "$seatRanker"
				
			fi
			
			val=${matrix[$(($counter/5)),$(($counter%5))]}
			if [ $val == "_" ]
			then
				printed=-1
				for i in "${numericSeatsBooked[@]}"
				do
					if [ $counter -eq $i ]
					then 
						echo -e -n "\e[1;34m   X\e[0m"
						matrix[$(($counter/5)),$(($counter%5))]="X"
						printed=1
						break
					fi
				done

				if [ $printed -eq -1 ]
				then
					echo -n "    "
				fi
				
			else
				echo -e -n "\e[1;31m   X\e[0m"
				
			fi

			let "counter=$counter+1"			
		done
		echo

	fi

	#seeks user confirmation for the optimally selected seats. In the event that the user confirms booking,
	#appropriate changes are made to the ticketlist.txt and seating.txt to reflect the booking.
	#In the event the user chooses to cancel the booking, the program quits with an appropriate message
	echo
	echo -e "\e[3;4mTotal ticket price for \e[1;31m$ticketsToBook\e[0m\e[3;4m tickets is AED \e[1;31m$ticketsToBook\e[0m\e[3;4m0\e[0m"
	read -p "To confirm your seats marked in blue, press Y or N: " confirmation

	case $confirmation in 
		"Y"*)
			echo -e "\e[1;32mYour Booking is confirmed! Thank you for using the Movie Ticketing System\e[0m"
			
			declare -A newTheatreRow
			theatreRowCounter=0
			lineToReplace=$startLine
			counter=0

			while [ $lineToReplace -lt $endLine ]
			do
				if [[ $(($counter % 5)) -eq 0 && $counter -ne 0 ]]
					then
						var="${newTheatreRow[@]}"
						sed -i "${lineToReplace}s/.*/$var/" seating.txt
						let "lineToReplace=$lineToReplace+1"
						theatreRowCounter=0
				fi
				newTheatreRow[$theatreRowCounter]="${matrix[$(($counter/5)),$(($counter%5))]}"
				let "theatreRowCounter=$theatreRowCounter+1"
				let "counter=$counter+1"
			done

			if [ $value -eq 1 ]
			then
				line=$(awk "/$movieTitle/{print NR}" ticketlist.txt)
				sed -i "${line}s/Yes/No/g" ticketlist.txt
			fi

			;;
		"N"*)
			echo -e "\e[1;32mYour Booking is cancelled! Thank you for using the Movie Ticketing System\e[0m"
			;;
		*)
			echo "Invalid choice"
		esac

}

#automatically selects the best seats based on the notion that centralized seats and those closer to the screen are superior
#to those on the corners or at those farther away from the screen
automaticallySelectBestSeat(){

	read -p "Enter the name of the movie to book tickets for: " movieTitle
	if grep -Fxq "$movieTitle" seating.txt
	then
		lineNumber=$(awk "/$movieTitle/{print NR}" seating.txt)
		startLine=$(($lineNumber+1))
		endLine=$(($startLine+4))
		declare -A matrix
		counter=0
		unbookedSeats=0
		bookedSeats=0
		
		for ch in `sed -n "${startLine},${endLine}p" seating.txt`
		do
			matrix[$(($counter/5)),$(($counter%5))]=$ch
			case $ch in 
				'_'*)
					let "unbookedSeats=unbookedSeats+1"
					;;
				'X'*)
					let "bookedSeats=bookedSeats+1"
					;;
			esac

			let "counter=$counter+1"
		done

		if [ $unbookedSeats -ge 1 ]
		then
			read -p "Enter number of tickets: " tickets
			if [ $tickets -eq 0 ]
			then 
				quitTheTicketingSystem
			elif [[ $tickets -lt 0 || $tickets -gt 20 ]]
			then
				echo "Invalid number of tickets!"
				return 1
			elif [ $tickets -gt $unbookedSeats ]
			then
				echo "$tickets tickets unavailable!"
			elif [ $tickets -eq $unbookedSeats ]
				then
					printTheTheatre 1 $tickets   #calls the printTheTheatre function to directly book all seats available
			else
				printTheTheatre 2 $tickets  #calls the printTheTheatre function to optimally book a specific
											#number of seats from those avaliable 
			fi
		else
			echo "Show sold out"
		fi
	else
		echo "Invalid movie name"
	fi

	
}

#enables manual selection of the seats for the concerned movie
manuallySelectSeats(){

	read -p "Enter the name of the movie to book tickets for: " movieTitle
	if grep -Fxq "$movieTitle" seating.txt
	then
		lineNumber=$(awk "/$movieTitle/{print NR}" seating.txt)
		startLine=$(($lineNumber+1))
		endLine=$(($startLine+4))
		declare -A matrix
		counter=0
		unbookedSeats=0
		bookedSeats=0
		
		for ch in `sed -n "${startLine},${endLine}p" seating.txt`
		do
			matrix[$(($counter/5)),$(($counter%5))]=$ch
			case $ch in 
				'_'*)
					let "unbookedSeats=unbookedSeats+1"
					;;
				'X'*)
					let "bookedSeats=bookedSeats+1"
					;;
			esac

			let "counter=$counter+1"
		done

		counter=0
		seatRanker=0
		
		echo -e "\e[4m\e[1;31;43mTo select theatre's seat manually\e[0m"
		echo
		echo -e "\e[4m\e[1;33;45m        SCREEN          \e[0m"
		echo -n "    A   B   C   D   E"

		while [ $counter -lt 20 ]
		do
			if [[ $(($counter % 5)) -eq 0 ]]
			then
				echo 
				let "seatRanker=$seatRanker+1"
				echo -n "$seatRanker"
				
			fi
				
			val="${matrix[$(($counter/5)),$(($counter%5))]}"
			if [ $val == "_" ]
			then
				echo -n "    "	
			else
				echo -e -n "\e[1;31m   X\e[0m"
			fi

			let "counter=$counter+1"	

		done
		echo
		declare -A seatsAvailable
		seatCounter=0
		counter=0
		
		#storing the seats available in an array seatsAvailable
		while [ $counter -lt 20 ]
		do		
			val=${matrix[$(($counter/5)),$(($counter%5))]}
			if [ $val == "_" ]
			then
				row=$(($(($counter/5))+1))
				columnNumber=$(($counter%5))

				case $columnNumber in

					0*) 
						column="A"
						;;
					1*) 
						column="B"
						;;
					2*) 
						column="C"
						;;
					3*) 
						column="D"
						;;
					4*) 
						column="E"
						;;
				esac

				seatsAvailable[$seatCounter]="$column$row"
				let "seatCounter=$seatCounter+1"
			fi

			let "counter=$counter+1"			

		done

		if [ $unbookedSeats -ge 1 ]
		then
			read -p "Enter number of tickets: " tickets
			if [ $tickets -eq 0 ]
			then
				quitTheTicketingSystem
				return 1
			elif [[ $tickets -lt 0 || $tickets -gt 20 ]]
			then
				echo "Invalid number of tickets!"
				return 1
			elif [ $tickets -gt $unbookedSeats ]
			then
				echo "$tickets tickets unavailable!"
				return 1	
			else
				
				#array to store the seats requested by the user
				declare -A requestedSeats
				requestedSeatsCounter=0
				requestSuccessful=0

				while [ $requestedSeatsCounter -lt $tickets ]
				do
					read -p "Enter seat#$(($requestedSeatsCounter+1)): " requestedSeats[$requestedSeatsCounter]

					found=-1

					#validation to ensure that the seat is valid and available
					for i in "${seatsAvailable[@]}"
					do
						if [ $i == "${requestedSeats[$requestedSeatsCounter]}" ]
						then
							found=0
							break
						fi
					done

					if [ $found -eq -1 ]
					then
						echo "Seat unavailable"
						return 1
						break
					fi
					let "requestedSeatsCounter=$requestedSeatsCounter+1"
				done

				#array to store a numeric representation of the available seats, to ease processing
				declare -A numericSeatsBooked
				numericSeatsBookedCounter=0

				for i in "${requestedSeats[@]}"
				do
					value=0
					case $i in
					"A1"*)
						value=0
						;;
					"B1"*)
						value=1
						;;
					"C1"*)
						value=2
						;;
					"D1"*)
						value=3
						;;
					"E1"*)
						value=4
						;;
					"A2"*)
						value=5
						;;
					"B2"*)
						value=6
						;;
					"C2"*)
						value=7
						;;
					"D2"*)
						value=8
						;;
					"E2"*)
						value=9
						;;
					"A3"*)
						value=10
						;;
					"B3"*)
						value=11
						;;
					"C3"*)
						value=12
						;;
					"D3"*)
						value=13
						;;
					"E3"*)
						value=14
						;;
					"A4"*)
						value=15
						;;
					"B4"*)
						value=16
						;;
					"C4"*)
						value=17
						;;
					"D4"*)
						value=18
						;;
					"E4"*)
						value=19
						;;
					esac

					numericSeatsBooked[$numericSeatsBookedCounter]=$value
					let "numericSeatsBookedCounter=$numericSeatsBookedCounter+1"

				done

				#prints the theatre seats (booked, unbooked, requested)
				echo -e "\e[4m\e[1;31;43mTo select theatre's seat manually\e[0m"
				echo
				echo -e "\e[4m\e[1;33;45m        SCREEN          \e[0m"
				echo -n "    A   B   C   D   E"

				counter=0
				seatRanker=0

				while [ $counter -lt 20 ]
				do
					if [[ $(($counter % 5)) -eq 0 ]]
					then
						echo 
						let "seatRanker=$seatRanker+1"
						echo -n "$seatRanker"
						
					fi
					
					val=${matrix[$(($counter/5)),$(($counter%5))]}
					if [ $val == "_" ]
					then
						printed=-1
						for i in "${numericSeatsBooked[@]}"
						do
							if [ $counter -eq $i ]
							then 
								echo -e -n "\e[1;34m   X\e[0m"
								matrix[$(($counter/5)),$(($counter%5))]="X"
								printed=1
								break
							fi
						done

						if [ $printed -eq -1 ]
						then
							echo -n "    "	
						fi
						
					else
						echo -e -n "\e[1;31m   X\e[0m"
					fi

					let "counter=$counter+1"			
				done
				echo 

			fi
				#seeks user confirmation for the requested booking. In the event that the user confirms booking,
				#appropriate changes are made to the ticketlist.txt and seating.txt to reflect the booking.
				#In the event the user chooses to cancel the booking, the program quits with an appropriate message
				echo
				echo -e "\e[3;4mTotal ticket price for \e[1;31m$tickets\e[0m\e[3;4m tickets is AED \e[1;31m$tickets\e[0m\e[3;4m0\e[0m"
				read -p "To confirm your seats marked in blue, press Y or N: " confirmation

				case $confirmation in 
					"Y"*)
						echo -e "\e[1;32mYour Booking is confirmed! Thank you for using the Movie Ticketing System\e[0m"
						
						declare -A newTheatreRow
						theatreRowCounter=0
						lineToReplace=$startLine
						counter=0

						while [ $lineToReplace -lt $endLine ]
						do
							if [[ $(($counter % 5)) -eq 0 && $counter -ne 0 ]]
								then
									var="${newTheatreRow[@]}"
									sed -i "${lineToReplace}s/.*/$var/" seating.txt
									let "lineToReplace=$lineToReplace+1"
									theatreRowCounter=0
							fi
							newTheatreRow[$theatreRowCounter]="${matrix[$(($counter/5)),$(($counter%5))]}"
							let "theatreRowCounter=$theatreRowCounter+1"
							let "counter=$counter+1"
						done

						counter=0
						bookedSeats=0
						unbookedSeats=0

						while [ $counter -lt 20 ]
						do
							val="${matrix[$(($counter/5)),$(($counter%5))]}"
							if [[ $val == "X" ]]
							then
								let "bookedSeats=$bookedSeats+1"
							else
								let "unbookedSeats=$unbookedSeats+1"	
							fi
								
							let "counter=$counter+1"	

						done

						if [ $bookedSeats -eq 20 ]
						then
							line=$(awk "/$movieTitle/{print NR}" ticketlist.txt)
							sed -i "${line}s/Yes/No/g" ticketlist.txt
						fi
						;;
					"N"*)
						echo -e "\e[1;32mYour Booking is cancelled! Thank you for using the Movie Ticketing System\e[0m"
						;;
					*)
						echo "Invalid choice"
					esac

		else
			echo "Show sold out"
		fi	
	else
		echo "Invalid movie name"
	fi
	
}

#prints an appropriate message to indicate quitting from the ticketing system
quitTheTicketingSystem(){
	echo "Thank you for using the Movie Ticket Booking System. Come again!"
}

#enables the user to search by Movie title or Showtime
movieSearch() {
	read -p "Enter S to search by Showtime or M to search by Movie Title: " choice
	case $choice in
		"M"*)
			read -p "Enter the movie title: " movieTitle
			if grep -Fxq "$movieTitle" seating.txt
			then
				echo "Search Results > "
				echo "Movie found:    True"
				echo -n "Movie Name:  "
				grep  "$movieTitle" ticketlist.txt | cut -d, -f2 
				echo -n "Show Time:      "
				grep  "$movieTitle" ticketlist.txt | cut -d, -f1
				echo -n "Availability:"
				grep  "$movieTitle" ticketlist.txt | cut -d, -f3
			else
				echo "Search Results > "
				echo "Movie is not screened by the theatre"
			fi
			;;
		"S"*)
			read -p "Enter the show time: " time
			length=${#time}
			if [[ $length -ne 4 || $time > "2359" || $time < "0000" ]]
			then 
				echo "Invalid time!"
				return 1
			fi

			if grep -Fq "$time" ticketlist.txt
			then
				echo "Movies showing at $time hours > "
				echo
				for i in `grep "$time" ticketlist.txt | cut -d, -f2`
				do
							
					echo -n "Movie title: " 
					grep  "$i" ticketlist.txt | cut -d, -f2 
					echo -n "Show Time:      "
					grep  "$i" ticketlist.txt | cut -d, -f1
					echo -n "Availability:"
					grep  "$i" ticketlist.txt | cut -d, -f3
					echo
				done
			else
				echo "No movies showing at $time hours"
			fi
			;;
		*)
			echo "Invalid choice!"
	esac
}

#start of the program. The program starts with calling the displayTheMenu function, followed by reading the user input
#and performing an appropriate action
displayTheMenu
read input
echo

#loop that continues asking the user's choice until 5 is pressed
#to quit the program
while [ $input -ne 5 ]
do
#validates user input to ensure the user has entered a valid option
	if [[ $input -lt 1 || $input -gt 5 ]]
	then
		echo "Invalid input"
	else
		
		case $input in
			1*)
			#invokes the function to display the movie titles, screening times and respective availabilities
			listMovieInformation
				;;
			2*)
			#invokes the function to automatically select the best seat(s) for the desired movie
			automaticallySelectBestSeat
				;;
			3*)
			#invokes the function to enable the user to manually select seat(s) for the desired movie
			manuallySelectSeats
				;;
			4*)
			#invokes the function to enable the user to search by movie title or showtime
			movieSearch
				;;
		esac

	fi
	echo
	echo
	displayTheMenu
	read input
	echo
done

quitTheTicketingSystem